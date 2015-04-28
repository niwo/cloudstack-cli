class Infrastack < CloudstackCli::Base

  desc "create STACKFILE", "create a stack of VMs"
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
          options = {
            name: name,
            displayname: instance["decription"],
            zone: instance["zone"] || stack["zone"],
            template: instance["template"],
            iso: instance["iso"] ,
            offering: instance["offering"],
            networks: load_string_or_array(instance["networks"]),
            project: stack["project"],
            disk_offering: instance["disk_offering"],
            size: instance["disk_size"],
            group: instance["group"] || stack["group"],
            keypair: instance["keypair"] || stack["keypair"],
            sync: true
          }
          jobs << {
            id: client.deploy_virtual_machine(
              vm_options_to_params(options),
              {sync: true}
            )['jobid'],
            name: "Create VM #{name}"
          }
        end
      end
    end
    watch_jobs(jobs)

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
    say "Finished.", :green
  end

  no_commands do
    def find_project_by_name(name)
      if name
        unless project_id = client.list_projects(name: name).first['id']
          say "Error: Project '#{name}' not found.", :red
          exit 1
        end
      else
        project_id = nil
      end
      project_id
    end

    def load_string_or_array(item)
     item.is_a?(Array) ? item : [item]
    end

    def string_to_array(string)
      string ? string.gsub(', ', ',').split(',') : nil
    end
  end

end
