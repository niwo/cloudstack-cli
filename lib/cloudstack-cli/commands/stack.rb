class Stack < CloudstackCli::Base

  desc "create STACKFILE", "create a stack of VMs"
  option :skip_forwarding_rules, default: false,
    type: :boolean, aliases: '-s',
    desc: "Skip creation of port forwarding rules."
  def create(stackfile)
    stack = parse_file(stackfile)
    project_id = find_project_by_name(stack["project"])

    say "Create stack #{stack["name"]}...", :green
    jobs = []
    stack["servers"].each do |instance|
      string_to_array(instance["name"]).each do |name|
        server = client.list_virtual_machines(name: name, project_id: project_id).first
        if server
          say "VM #{name} (#{server["state"]}) already exists.", :yellow
          jobs << {
            id: 0,
            name: "Create VM #{name}",
            status: 1
          }
        else
          options.merge!({
            name: name,
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
          jobs << {
            id: client.deploy_virtual_machine(
              vm_options_to_params,
              {sync: true}
            )['jobid'],
            name: "Create VM #{name}"
          }
        end
      end
    end
    watch_jobs(jobs)

    unless options[:skip_forwarding_rules]
      say "Check for port forwarding rules...", :green
      jobs = []
      stack["servers"].each do |instance|
        string_to_array(instance["name"]).each do |name|
          if port_rules = string_to_array(instance["port_rules"])
            server = client.list_virtual_machines(name: name, project_id: project_id).first
            create_port_rules(server, port_rules, false).each_with_index do |job_id, index|
              jobs << {
                id: job_id,
                name: "Create port forwarding rules (#{port_rules[index]}) for VM #{name}"
              }
            end
          end
        end
      end
      watch_jobs(jobs)
    end

    say "Finished.", :green
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
  def destroy(stackfile)
    stack = parse_file(stackfile)
    project_id = find_project_by_name(stack["project"])
    servers = []
    stack["servers"].each do |server|
      string_to_array(server["name"]).each {|name| servers << name}
    end

    if options[:force] || yes?("Destroy the following VM #{servers.join(', ')}? [y/N]:", :yellow)
      jobs = []
      servers.each do |name|
        if server = client.list_virtual_machines(name: name, project_id: project_id).first
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

  end # no_commands

end
