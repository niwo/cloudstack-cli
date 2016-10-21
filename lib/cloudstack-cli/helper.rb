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
      2  => "error",
      3  => "aborted"
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
      say "Completed: #{completed} of #{jobs.size} (#{t_elapsed}s)", :magenta
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
      frontendip_id = nil
      jobs = []
      client.verbose = async
      project_id = server['projectid'] || nil
      port_rules.each do |pf_rule|
        pf_rule = pf_rule_to_object(pf_rule)
        if pf_rule[:ipaddress]
          pub_ip = client.list_public_ip_addresses(
            network_id: get_server_default_nic(server)["networkid"],
            project_id: project_id,
            ipaddress: pf_rule[:ipaddress]
          )
          ip_addr = pub_ip.find { |addr| addr['ipaddress'] == pf_rule[:ipaddress]} if pub_ip
          if ip_addr
            frontendip = ip_addr['id']
          else
            say "Error: IP #{pf_rule[:ipaddress]} not found.", :red
            next
          end
        end

        # check if there is already an existing rule
        rules = client.list_port_forwarding_rules(
          networkid: get_server_default_nic(server)["networkid"],
          ipaddressid: frontendip_id,
          projectid: project_id
        )
        existing_pf_rules = rules.find do |rule|
          # remember matching address for additional rules
          frontendip_id = rule['ipaddressid'] if rule['virtualmachineid'] == server['id']

          rule['virtualmachineid'] == server['id'] &&
          rule['publicport'] == pf_rule[:publicport] &&
          rule['privateport'] == pf_rule[:privateport] &&
          rule['protocol'] == pf_rule[:protocol]
        end

        if existing_pf_rules
          say "Port forwarding rule on port #{pf_rule[:privateport]} for VM #{server["name"]} already exists.", :yellow
        else
          unless frontendip_id
            frontendip_id = client.associate_ip_address(
              network_id: get_server_default_nic(server)["networkid"],
              project_id: project_id
            )['ipaddress']['id']
          end
          args = pf_rule.merge({
            ipaddressid: frontendip_id,
            virtualmachineid: server["id"]
          })
          if async
            say "Create port forwarding rule #{pf_rule[:ipaddress]}:#{port} for VM #{server["name"]}.", :yellow
            client.create_port_forwarding_rule(args)
            return
          else
            jobs << client.create_port_forwarding_rule(args, {sync: true})['jobid']
          end
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

    def get_server_default_nic(server)
      server['nic'].each do |nic|
        return nic if nic['isdefault']
      end
    end

    def pf_rule_to_object(pf_rule)
      pf_rule = pf_rule.split(":")
      {
        ipaddress: (pf_rule[0] == '' ? nil : pf_rule[0]),
        privateport: pf_rule[1],
        publicport: (pf_rule[2] || pf_rule[1]),
        protocol: (pf_rule[3] || 'tcp').downcase
      }
    end

  end
end
