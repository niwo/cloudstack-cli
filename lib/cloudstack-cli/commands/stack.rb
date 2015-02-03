require 'open-uri'

class Stack < CloudstackCli::Base

  desc "create STACKFILE", "create a stack of servers"
  def create(stackfile)
    stack = parse_stackfile(stackfile)
    say "Create stack #{stack["name"]}...", :green
    projectid = find_project(stack["project"])['id'] if stack["project"]
    jobs = []
    client.verbose = false
    stack["servers"].each do |instance|
      string_to_array(instance["name"]).each do |name|
        server = client.get_server(name, project_id: projectid)
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
      string_to_array(instance["name"]).each do |name|
        if port_rules = string_to_array(instance["port_rules"])
          server = client(quiet: true).get_server(name, project_id: projectid)
          create_port_rules(server, port_rules, false).each_with_index do |job_id, index|
            jobs << {
              id: job_id,
              name: "Create port forwarding rules (#{port_rules[index]}) for server #{name}"
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
    desc: "destroy without asking",
    type: :boolean,
    default: false,
    aliases: '-f'
  option :expunge,
    desc: "expunge servers immediately",
    type: :boolean,
    default: false,
    aliases: '-E'
  def destroy(stackfile)
    stack = parse_stackfile(stackfile)
    projectid = find_project(stack["project"])['id'] if stack["project"]
    client.verbose = false
    servers = []
    stack["servers"].each do |server|
      string_to_array(server["name"]).each {|name| servers << name}
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
      handler = case File.extname(stackfile)
      when ".json"
        Object.const_get "JSON"
      when ".yaml", ".yml"
        Object.const_get "YAML"
      else
        say "File extension #{File.extname(stackfile)} not supported. Supported extensions are .json, .yaml or .yml", :red
        exit
      end
      begin
        return handler.load open(stackfile){|f| f.read}
      rescue SystemCallError
        say "Can't find the stack file #{stackfile}.", :red
        exit 1
      rescue => e
        say "Error parsing #{File.extname(stackfile)} file:", :red
        say e.message
        exit 1
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
