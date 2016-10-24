class Stack < CloudstackCli::Base

  desc "create STACKFILE", "create a stack of VM's"
  option :limit, type: :array, aliases: '-l',
    desc: "Limit on specific server names."
  option :skip_forwarding_rules, default: false,
    type: :boolean, aliases: '-s',
    desc: "Skip creation of port forwarding rules."
  option :concurrency, type: :numeric, default: 10, aliases: '-C',
    desc: "number of concurrent commands to execute"
  option :assumeyes, type: :boolean, default: false, aliases: '-y',
    desc: "answer yes for all questions"
  def create(stackfile)
    stack = parse_file(stackfile)
    project_id = find_project_by_name(stack["project"])

    say "Create stack #{stack["name"]}...", :green
    jobs = []
    stack["servers"].each do |instance|
      string_to_array(instance["name"]).each do |name|
        if !options[:limit] || options[:limit].include?(name)
          if server = client.list_virtual_machines(
            name: name, project_id: project_id, listall: true
          ).find {|vm| vm["name"] == name }
            say "VM #{name} (#{server["state"]}) already exists.", :yellow
            jobs << {
              id: 0,
              name: "Create VM #{name}",
              status: 3
            }
          else
            options.merge!({
              displayname: instance["decription"],
              zone: instance["zone"] || stack["zone"],
              project: stack["project"],
              template: instance["template"],
              iso: instance["iso"] ,
              offering: instance["offering"],
              networks: load_string_or_array(instance["networks"]),
              ip_network_list: instance["ip_network_list"],
              disk_offering: instance["disk_offering"],
              size: instance["disk_size"],
              group: instance["group"] || stack["group"],
              keypair: instance["keypair"] || stack["keypair"],
              ip_address: instance["ip_address"]
            })
            vm_options_to_params
            jobs << {
              job_id: nil,
              args: options.merge(name: name),
              name: "Create VM #{name}",
              status: -1
            }
          end
        end
      end
    end

    if jobs.count{|job| job[:status] < 1 } > 0
      run_background_jobs(jobs, "deploy_virtual_machine")
    end

    # count jobs with status 1 => Completed
    successful_jobs = jobs.count {|job| job[:status] == 1 }
    unless successful_jobs == 0 || options[:skip_forwarding_rules]
      say "Check for port forwarding rules...", :green
      pjobs = []
      jobs.select{|job| job[:status] == 1}.each do |job|
        vm = job[:result]["virtualmachine"]
        vm_def = find_vm_in_stack(vm["name"], stack)
        if port_rules = string_to_array(vm_def["port_rules"])
          create_port_rules(vm, port_rules, false).each_with_index do |job_id, index|
            job_name = "Create port forwarding rules (#{port_rules[index]}) for VM #{vm["name"]}"
            pjobs << {id: job_id, name: job_name}
          end
        end
      end
      watch_jobs(pjobs)
      pjobs.each do |job|
        if job[:result]
          result = job[:result]["portforwardingrule"]
          puts "Created port forwarding rule #{result['ipaddress']}:#{result['publicport']} => #{result['privateport']} for VM #{result['virtualmachinename']}"
        end
      end
    end
    say "Finished.", :green

    if successful_jobs > 0
      if options[:assumeyes] || yes?("Display password(s) for VM(s)? [y/N]:", :yellow)
        pw_table = [%w(VM Password)]
        jobs.select {|job| job[:status] == 1 && job[:result] }.each do |job|
          if result = job[:result]["virtualmachine"]
            pw_table << ["#{result["name"]}:", result["password"] || "n/a"]
          end
        end
        print_table(pw_table) if pw_table.size > 0
      end
    end
  end

  desc "destroy STACKFILE", "destroy a stack of VMs"
  option :force,
    desc: "destroy without asking",
    type: :boolean,
    default: false,
    aliases: '-f'
  option :expunge,
    desc: "expunge VMs immediately",
    type: :boolean,
    default: false,
    aliases: '-E'
  option :limit, type: :array, aliases: '-l',
    desc: "Limit on specific server names."
  def destroy(stackfile)
    stack = parse_file(stackfile)
    project_id = find_project_by_name(stack["project"])
    servers = []
    stack["servers"].each do |server|
      string_to_array(server["name"]).each do |name|
        if !options[:limit] || options[:limit].include?(name)
          servers << name
        end
      end
    end

    if servers.size == 0
      say "No servers in stack selected.", :yellow
      exit
    end

    if options[:force] ||
      yes?("Destroy #{'and expunge ' if options[:expunge]}the following VM(s)? #{servers.join(', ')} [y/N]:", :yellow)
      jobs = []
      servers.each do |name|
        if server = client.list_virtual_machines(
          name: name, project_id: project_id, listall: true
          ).find {|vm| vm["name"] == name }
          jobs << {
            id: client.destroy_virtual_machine(
              { id: server['id'], expunge: options[:expunge] },
              { sync: true }
            )['jobid'],
            name: "Destroy VM #{name}"
          }
        end
      end
      watch_jobs(jobs)
      say "Finished.", :green
    end
  end

  no_commands do
    def find_project_by_name(name)
      if name
        unless project = client.list_projects(name: name, listall: true).first
          say "Error: Project '#{name}' not found.", :red
          exit 1
        end
        project_id = project['id']
      else
        project_id = nil
      end
      project_id
    end

    def load_string_or_array(item)
      return nil if item == nil
      item.is_a?(Array) ? item : [item]
    end

    def string_to_array(string)
      string ? string.gsub(', ', ',').split(',') : nil
    end

    def find_vm_in_stack(name, stack)
      stack["servers"].each do |server|
        if string_to_array(server["name"]).find{|n| n == name }
          return server
        end
      end
    end

  end # no_commands

end
