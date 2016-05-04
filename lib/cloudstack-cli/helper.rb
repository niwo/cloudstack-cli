module CloudstackCli
  module Helper
    def print_options(options, attr = 'name')
      options.to_enum.with_index(1).each do |option, i|
         puts "#{i}: #{option[attr]}"
      end
    end

    def ask_number(question)
      number = ask(question).to_i - 1
      number < 0 ? 0 : number
    end

    ASYNC_STATES = {
      -1 => "waiting",
      0  => "running",
      1  => "completed",
      2  => "error"
    }

    def watch_jobs(jobs)
      chars = %w(| / - \\)
      call = 0
      opts = {t_start: Time.now}
      jobs = update_job_status(jobs)
      while jobs.select{|job| job[:status].to_i < 1 }.size > 0 do
        if call.modulo(40) == 0
          t = Thread.new { jobs = update_job_status(jobs) }
          while t.alive?
            chars = print_job_status(jobs, chars,
              call == 0 ? opts.merge(no_clear: true) : opts
            )
            call += 1
          end
          t.join
        else
          chars = print_job_status(jobs, chars,
            call == 0 ? opts.merge(no_clear: true) : opts
          )
          call += 1
        end
      end
      print_job_status(jobs, chars,
        call == 0 ? opts.merge(no_clear: true) : opts
      )
    end

    def update_job_status(jobs)
      jobs.each do |job|
        job[:status] = 0 unless job[:status]
        if job[:status] == 0
          job[:status] = client.query_async_job_result(job_id: job[:id])['jobstatus']
        end
      end
      jobs
    end

    def run_background_jobs(jobs, command)
      view_thread = Thread.new do
        chars = %w(| / - \\)
        call = 0
        opts = {t_start: Time.now}

        while jobs.select{|job| job[:status] < 1 }.size > 0 do
          if call.modulo(40) == 0
            t = Thread.new { jobs = update_jobs(jobs, command) }
            while t.alive?
              chars = print_job_status(jobs, chars,
                call == 0 ? opts.merge(no_clear: true) : opts
              )
              call += 1
            end
            t.join
          else
            chars = print_job_status(jobs, chars,
              call == 0 ? opts.merge(no_clear: true) : opts
            )
            call += 1
          end
        end
        print_job_status(jobs, chars,
          call == 0 ? opts.merge(no_clear: true) : opts
        )
      end
      view_thread.join
    end

    def update_jobs(jobs, command)
      # update running job status
      threads = jobs.select{|job| job[:status] == 0 }.map do |job|
        Thread.new do
          job[:status] = client.query_async_job_result(job_id: job[:job_id])['jobstatus']
        end
      end
      threads.each(&:join)

      # launch new jobs if required and possible
      launch_capacity = options[:concurrency] - jobs.select{|job| job[:status] == 0 }.count
      threads = []
      jobs.select{|job| job[:status] == -1 }.each do |job|
        if launch_capacity > 0
          threads << Thread.new do
            job[:job_id] = client.send(
              command, { id: job[:object_id] }, { sync: true }
            )['jobid']
            job[:status] = 0
          end
          launch_capacity -= 1
        end
      end
      threads.each(&:join)
      jobs
    end

    def print_job_status(jobs, spinner, opts = {t_start: Time.now})
      print ("\r" + "\e[A\e[K" * (jobs.size + 1)) unless opts[:no_clear]
      jobs.each_with_index do |job, i|
        print "#{job[:name]} : job #{ASYNC_STATES[job[:status]]} "
        puts job[:status] == 0 ? spinner.first : ""
      end
      t_elapsed = opts[:t_start] ? (Time.now - opts[:t_start]).round(1) : 0
      completed = jobs.select{|j| j[:status] == 1}.size
      say "Completed: #{completed}/#{jobs.size} (#{t_elapsed}s)", :magenta
      sleep opts[:sleeptime] || 0.1
      spinner.push spinner.shift
      spinner
    end

    def bootstrap_server(args = {})
      if args[:project] && project = find_project(args[:project])
        project_id = project["id"]
        project_name = project['name']
      end

      if args[:name]
        args['displayname'] = args[:name]
        name = args[:name]
      elsif args[:displayname]
        name = args[:displayname]
      end

      unless server = client.list_virtual_machines(name: args[:name], project_id: project_id).first
        say "Create VM #{name}...", :yellow
        server = client.deploy_virtual_machine(args)
        puts
        say "VM #{name} has been created.", :green
      else
        say "VM #{name} already exists (#{server["state"]}).", :yellow
      end

      if args[:port_rules] && args[:port_rules].size > 0
        create_port_rules(server, args[:port_rules])
      end
      server
    end

    def create_server(args = {})
      if args[:project] && project = find_project(args[:project])
        project_id = project["id"]
        project_name = project['name']
      end
      unless server = client.list_virtual_machines(name: args[:name], project_id: project_id)
        server = client.deploy_virtual_machine(args)
      end
      server
    end

    def create_port_rules(server, port_rules, async = true)
      frontendip = nil
      jobs = []
      client.verbose = async
      project_id = server['projectid'] || nil
      port_rules.each do |pf_rule|
        ip = pf_rule.split(":")[0]
        if ip != ''
          ip_addr = client.get_public_ip_address(ip, project_id)
          unless ip_addr
            say "Error: IP #{ip} not found.", :red
            next
          end
        else
          ip_addr = frontendip ||= client.associate_ip_address(
            network_id: server["nic"].first["networkid"]
          )["ipaddress"]
        end
        port = pf_rule.split(":")[1]
        args = {
          ipaddressid: ip_addr["id"],
          publicport: port,
          privateport: port,
          protocol: 'TCP',
          virtualmachineid: server["id"]
        }
        if async
          say "Create port forwarding rule #{ip_addr['ipaddress']}:#{port} for server #{server["name"]}.", :yellow
          client.create_port_forwarding_rule(args)
          return
        else
          jobs << client.create_port_forwarding_rule(args, {sync: true})['jobid']
        end
      end
      jobs
    end

    def bootstrap_server_interactive
      zones = client.list_zones
      if zones.size > 1
        say "Select a availability zone:", :yellow
        print_options(zones)
        zone = ask_number("Zone Nr.: ")
      else
        zone = 0
      end

      projects = client.list_projects
      project_id = nil
      if projects.size > 0
        if yes?("Do you want to deploy your VM within a project? (y/N)") && projects.size > 0
          say "Select a project", :yellow
          print_options(projects)
          project = ask_number("Project Nr.: ")
          project_id = projects[project]['id'] rescue nil
        end
      end

      say "Please provide a name for the new VM", :yellow
      say "(spaces or special characters are NOT allowed)"
      server_name = ask("Server name: ")

      server_offerings = client.list_service_offerings
      say "Select a computing offering:", :yellow
      print_options(server_offerings)
      service_offering = ask_number("Offering Nr.: ")

      templates = client.list_templates(project_id: project_id, zone_id: zones[zone]["id"], template_filter: "executable")
      say "Select a template:", :yellow
      print_options(templates)
      template = ask_number("Template Nr.: ")

      networks = client.list_networks(project_id: project_id, zone_id: zones[zone]["id"])
      if networks.size > 1
        say "Select a network:", :yellow
        print_options(networks)
        network = ask_number("Network Nr.: ")
      else
        network = 0
      end

      say "You entered the following configuration:", :yellow
      table =  [["Zone", zones[zone]["name"]]]
      table << ["VM Name", server_name]
      table << ["Template", templates[template]["name"]]
      table << ["Offering", server_offerings[service_offering]["name"]]
      table << ["Network", networks[network]["name"]]
      table << ["Project", projects[project]["name"]] if project
      print_table table

      if yes? "Do you want to deploy this VM? (y/N)"
        bootstrap_server(
          name: server_name,
          zone_id: zones[zone]["id"],
          template_id: templates[template]["id"],
          serviceoffering_id: server_offerings[service_offering]["id"],
          network_ids: network ? networks[network]["id"] : nil,
          project_id: project_id
        )
      end
    end

    ##
    # Finds the public ip for a server

    def get_server_public_ip(server, cached_rules=nil)
      return nil unless server

      # find the public ip
      nic = get_server_default_nic(server) || {}
      if nic['type'] == 'Virtual'
        ssh_rule = get_ssh_port_forwarding_rule(server, cached_rules)
        ssh_rule ? ssh_rule['ipaddress'] : nil
      else
        nic['ipaddress']
      end
    end

    ##
    # Gets the SSH port forwarding rule for the specified server.

    def get_ssh_port_forwarding_rule(server, cached_rules=nil)
      rules = cached_rules || client.list_port_forwarding_rules(project_id: server["projectid"]) || []
      rules.find_all { |r|
        r['virtualmachineid'] == server['id'] &&
            r['privateport'] == '22'&&
            r['publicport'] == '22'
      }.first
    end

    ##
    # Returns the fully qualified domain name for a server.

    def get_server_fqdn(server)
      return nil unless server

      nic = get_server_default_nic(server) || {}
      networks = client.list_networks(project_id: server['projectid']) || {}

      id = nic['networkid']
      network = networks.select { |net|
        net['id'] == id
      }.first
      return nil unless network

      "#{server['name']}.#{network['networkdomain']}"
    end

    def get_server_default_nic(server)
      server['nic'].each do |nic|
        return nic if nic['isdefault']
      end
    end

  end
end
