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

    def get_async_job_status(ids)
      ids.map do |id|
        client.query_job(id)['jobstatus']
      end
    end

    def watch_jobs(jobs)
      chars = %w(| / - \\)
      async_state = {0 => "running", 1 => "completed", 2 => "error"}
      status = get_async_job_status(jobs.map {|job| job[:id]})
      call = 0
      while status.include?(0) do
        status = call.modulo(40) == 0 ? get_async_job_status(jobs.map {|job| job[:id]}) : status
        print ("\r" + "\e[A\e[K" * (status.size)) if call > 0

        status.each_with_index do |job_status, i|
          puts "#{jobs[i][:name]} : job #{async_state[job_status]}  #{chars[0]}"
        end

        sleep 0.1
        chars.push chars.shift
        call += 1
      end
      
      print ("\r" + "\e[A\e[K" * (status.size))
      status.each_with_index do |job_status, i|
        puts "#{jobs[i][:name]} : job #{async_state[job_status]}"
      end
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
        frontendip = nil
        args[:port_rules].each do |pf_rule|
          ip = pf_rule.split(":")[0]
          if ip != ''
            ip_addr = client.get_public_ip_address(ip)
          else
            ip_addr = frontendip ||= client.associate_ip_address(
              server["nic"].first["networkid"]
            )
          end
          port = pf_rule.split(":")[1]
          say "Create port forwarding rule #{ip_addr['ipaddress']}:#{port} for server #{args[:name]}.", :yellow
          client.create_port_forwarding_rule(ip_addr["id"], port, 'TCP', port, server["id"])
        end
      end
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