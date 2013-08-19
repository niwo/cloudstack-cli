class Stack < CloudstackCli::Base

	desc "create STACKFILE", "create a stack of servers"
  def create(stackfile)
  	stack = parse_stackfile(stackfile)
    say "Create stack #{stack["name"]}..."
    threads = []
    stack["servers"].each do |server|
      server["name"].split(', ').each_with_index do |name, i|
        threads << Thread.new(i) {
          bootstrap_server(
            name: name,
            displayname: server["decription"],
            zone: server["zone"] || stack["zone"],
            template: server["template"],
            iso: server["iso"] ,
            offering: server["offering"],
            networks: string_to_array(server["networks"]),
            port_rules: string_to_array(server["port_rules"]),
            project: stack["project"],
            disk_offering: server["disk_offering"],
            disk_size: server["disk_size"],
            group: server["group"] || stack["group"],
            keypair: server["keypair"] || stack["keypair"]
          )
        }
      end
    end
    threads.each {|t| t.join }
  end

  desc "destroy STACKFILE", "destroy a stack of servers"
  option :force,
    description: "destroy without asking",
    type: :boolean,
    default: false,
    aliases: '-f'
  def destroy(stackfile)
    stack = parse_stackfile(stackfile)
    servers = []
    server = stack["servers"].collect do |server|
      server["name"].split(', ').each {|name| servers << name}
    end
    say "Destroy stack #{stack["name"]}...", :yellow
    puts
    invoke "server:destroy", servers, project: stack["project"], force: options[:force]
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

    def string_to_array(string)
      string ? string.gsub(', ', ',').split(', ') : nil
    end
  end

end