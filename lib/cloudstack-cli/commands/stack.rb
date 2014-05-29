class Stack < CloudstackCli::Base

	desc "create STACKFILE", "create a stack of servers"
  def create(stackfile)
  	stack = parse_stackfile(stackfile)
    say "Create stack #{stack["name"]}...", :green
    projectid = find_project(stack["project"])['id'] if stack["project"]
    jobs = []
    client.verbose = false
    stack["servers"].each do |instance|
      instance["name"].gsub(', ', ',').split(',').each do |name|
        server = client.get_server(name, {project_id: projectid})
        if server
          say "Server #{name} (#{server["state"]}) already exists.", :yellow
          jobs << {
            id: 0,
            name: "Create server #{name}",
            status: 1
          }
        else
          jobs << {
            id: client.create_server(
              {
                name: name,
                displayname: instance["decription"],
                zone: instance["zone"] || stack["zone"],
                template: instance["template"],
                iso: instance["iso"] ,
                offering: instance["offering"],
                networks: load_string_or_array(instance["networks"]),
                project: stack["project"],
                disk_offering: instance["disk_offering"],
                disk_size: instance["disk_size"],
                group: instance["group"] || stack["group"],
                keypair: instance["keypair"] || stack["keypair"],
                sync: true
              }
            )['jobid'],
            name: "Create server #{name}"
          }
        end
      end
    end
    watch_jobs(jobs)
    
    say "Check for port forwarding rules...", :green
    jobs = []
    stack["servers"].each do |instance|
      instance["name"].gsub(', ', ',').split(',').each do |name|
        if port_rules = string_to_array(instance["port_rules"])
          server = client(quiet: true).get_server(name, project_id: projectid)
          create_port_rules(server, port_rules, false).each_with_index do |job_id, index|
            jobs << {
              id: job_id,
              name: "Create port forwarding ##{index + 1} rules for server #{name}"
            }
          end
        end
      end
    end
    watch_jobs(jobs)
    say "Finished.", :green
  end

  desc "destroy STACKFILE", "destroy a stack of servers"
  option :force,
    description: "destroy without asking",
    type: :boolean,
    default: false,
    aliases: '-f'
  option :expunge,
    description: "expunge servers immediately",
    type: :boolean,
    default: false,
    aliases: '-e'
  def destroy(stackfile)
    stack = parse_stackfile(stackfile)
    projectid = find_project(stack["project"])['id'] if stack["project"]
    client.verbose = false
    servers = []
    stack["servers"].each do |server|
      server["name"].gsub(', ', ',').split(',').each {|name| servers << name}
    end

    if options[:force] || yes?("Destroy the following servers #{servers.join(', ')}? [y/N]:", :yellow)
      jobs = []
      servers.each do |name|
        server = client(quiet: true).get_server(name, project_id: projectid)
        if server
          jobs << {
            id: client.destroy_server(
              server['id'], {
                sync: true,
                expunge: options[:expunge]
              }
            )['jobid'],
            name: "Destroy server #{name}"
          }
        end
      end
      watch_jobs(jobs)
      say "Finished.", :green
    end
  end

  no_commands do
    def parse_stackfile(stackfile)
      begin
        return JSON.parse File.read(stackfile)
      rescue SystemCallError
        $stderr.puts "Can't find the stack file #{stackfile}."
      rescue JSON::ParserError => e
        $stderr.puts "Error parsing json file.\n#{e.message}."
        exit
      end
    end

    def load_string_or_array(item)
     item.is_a?(Array) ? item : [item]
    end

    def string_to_array(string)
      string ? string.gsub(', ', ',').split(',') : nil
    end
  end

end
