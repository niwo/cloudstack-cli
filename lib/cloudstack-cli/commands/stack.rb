class Stack < CloudstackCli::Base

	desc "create STACKFILE", "create a stack of servers"
  def create(stackfile)
  	stack = parse_stackfile(stackfile)
    say "Create stack #{stack["name"]}..."
    puts
    threads = []
    stack["servers"].each do |server|
      server["name"].split(', ').each_with_index do |name, i|
        threads << Thread.new(i) {
          CloudstackCli::Helper.new(options[:config]).bootstrap_server(
            name,
            server["zone"] || stack["zone"],
            server["template"],
            server["offering"],
            server["networks"] ? server["networks"].split(', ') : nil,
            server["port_rules"] ? server["port_rules"].split(', ') : nil,
            stack["project"]
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
  end

end