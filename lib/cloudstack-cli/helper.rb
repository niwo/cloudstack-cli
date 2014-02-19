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
          job[:status] = client.query_job(job[:id])['jobstatus']
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
      puts "Runtime: #{t_elapsed}s"
      sleep opts[:sleeptime] || 0.1
      spinner.push spinner.shift
      spinner
    end

    def bootstrap_server(args = {})
      if args[:project] && project = client(quiet: true).get_project(args[:project])
        project_id = project["id"]
        project_name = project['name']
      end
      server = client(quiet: true).get_server(args[:name], project_id)
      unless server
        say "Create server #{args[:name]}...", :yellow
        server = client.create_server(args)
        say "Server #{server["name"]} has been created.", :green
        client.wait_for_server_state(server["id"], "Running")
        say "Server #{server["name"]} is running.", :green
      else
        say "Server #{args[:name]} already exists (#{server['state']}).", :yellow
      end

      if args[:port_rules] && args[:port_rules].size > 0
        create_port_rules(server, args[:port_rules])
      end
      server
    end

    def create_server(args = {})
      if args[:project] && project = client(quiet: true).get_project(args[:project])
        project_id = project["id"]
        project_name = project['name']
      end
      server = client(quiet: true).get_server(args[:name], project_id)
      unless server
        server = client.create_server(args)
      end
      server
    end

    def create_port_rules(server, port_rules, async = true)
      frontendip = nil
      jobs = []
      client.verbose = async
      project_id = server['project'] ? client.get_project(server['project'])['id'] : nil
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
            server["nic"].first["networkid"]
          )
        end
        port = pf_rule.split(":")[1]
        if async 
          say "Create port forwarding rule #{ip_addr['ipaddress']}:#{port} for server #{server["name"]}.", :yellow
          client.create_port_forwarding_rule(ip_addr["id"], port, 'TCP', port, server["id"])
          return
        else
          jobs << client.create_port_forwarding_rule(
            ip_addr["id"],
            port, 'TCP', port, server["id"],
            false
          )['jobid']
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
      if yes?("Do you want to deploy your server within a project?") && projects.size > 0
        if projects.size > 0
          say "Select a project", :yellow
          print_options(projects)
          project = ask_number("Project Nr.: ")
        end
        project_id = projects[project]['id'] rescue nil
      end

      say "Please provide a name for the new server", :yellow
      say "(spaces or special characters are NOT allowed)"
      server_name = ask("Server name: ")

      server_offerings = client.list_service_offerings
      say "Select a computing offering:", :yellow
      print_options(server_offerings)
      service_offering = ask_number("Offering Nr.: ")

      templates = client.list_templates(project_id: project_id, zone_id: zones[zone]["id"])
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
      table << ["Server Name", server_name]
      table << ["Template", templates[template]["name"]]
      table << ["Offering", server_offerings[service_offering]["name"]]
      table << ["Network", networks[network]["name"]]
      table << ["Project", projects[project]["name"]] if project
      print_table table

      if yes? "Do you want to deploy this server?"
        bootstrap_server(
          server_name,
          zones[zone]["name"],
          templates[template]["name"],
          server_offerings[service_offering]["name"],
          [networks[network]["name"]], nil,
          project ? projects[project]["name"] : nil
        )
      end
    end

  end
end