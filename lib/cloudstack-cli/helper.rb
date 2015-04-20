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
      0 => "running",
      1 => "completed",
      2 => "error"
    }

    def watch_jobs(jobs)
      chars = %w(| / - \\)
      call = 0
      opts = {t_start: Time.now}
      jobs = update_job_status(jobs)
      while jobs.select{|job| job[:status] == 0}.size > 0 do
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
        unless job[:status] && job[:status] > 0
          job[:status] = client.query_async_job_result(job_id: job[:id])['jobstatus']
        end
      end
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

    def vm_options_to_params(options)
      params = {}

      zones = client.list_zones
      zone = options[:zone] ? zones.find {|z| z['name'] == options[:zone] } : zones.first
      if !zone
        msg = options[:zone] ? "Zone '#{options[:zone]}' is invalid." : "No zone found."
        say "Error: #{msg}", :red
        exit 1
      end
      params[:zone_id] = zone['id']

      if options[:project]
        if project = client.list_projects(name: options[:project]).first
          params[:project_id] = project['id']
        else
          say "Error: Project #{options[:project]} not found.", :red
          exit 1
        end
      end

      if offering = client.list_service_offerings(name: options[:offering]).first
        params[:service_offering_id] = offering['id']
      else
        say "Error: Offering #{options[:offering]} not found.", :red
        exit 1
      end

      if options[:template]
        if template = client.list_templates(name: options[:template], template_filter: "all").first
          params[:template_id] = template['id']
        else
          say "Error: Template #{options[:template]} not found.", :red
          exit 1
        end
      end

      if options[:disk_offering]
        unless disk_offering = client.list_disk_offerings(name: options[:disk_offering]).first
          say "Error: Disk offering '#{options[:disk_offering]}' is invalid.", :red
          exit 1
        end
        params[:diskoffering_id] = disk_offering['id']
      end

      if options[:iso]
        unless iso = client.list_isos(name: options[:iso]).first
          say "Error: Iso '#{args[:iso]}' is invalid.", :red
          exit 1
        end
        unless params[:diskoffering_id] || options[:diskoffering_id]
          say "Error: a disk offering is required when using iso.", :red
          exit 1
        end
        params['hypervisor'] = (options[:hypervisor] || 'vmware')
      end

      if !template && !iso
        say "Error: Iso or Template is required.", :red
        exit 1
      end
      params[:template_id] = template ? template['id'] : iso['id']

      networks = []
      if options[:networks]
        options[:networks].each do |name|
          network = client.list_networks(
            name: name,
            zone_id: params[:zone_id],
            project_id: params[:project_id]
          ).first
          if !network
            say "Error: Network '#{name}' not found.", :red
            exit 1
          end
          networks << network
        end
      end
      if networks.empty?
        #unless default_network = client.list_networks(project_id: params[:project_id]).find {
        #  |n| n['isdefault'] == true }
        unless default_network = client.list_networks(project_id: params[:project_id]).first
          say "Error: No default network found.", :red
          exit 1
        end
        networks << default_network
      end
      params[:network_ids] = networks.map {|n| n['id']}.join(',')
      params
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
          )
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

      templates = client.list_templates(project_id: project_id, zone_id: zones[zone]["id"], template_filter: "all")
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
