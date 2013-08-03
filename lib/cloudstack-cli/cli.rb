module CloudstackCli
  class Cli < CloudstackCli::Base
    include Thor::Actions

    package_name "cloudstack-cli" 
    map %w(-v --version) => :version 

    class_option :config,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'localition of your cloudstack-cli configuration file'

    desc "version", "outputs the cloudstack-cli version"
    def version
      say "cloudstack-cli v#{CloudstackCli::VERSION}"
    end

    desc "setup", "initial setup of the Cloudstack connection"
    option :url
    option :api_key
    option :secret_key
    def setup(file = options[:config])
      config = {}
      unless options[:url]
        say "What's the URL of your Cloudstack API?", :yellow
        say "Example: https://my-cloudstack-server/client/api/", :yellow
        config[:url] = ask("URL:", :magenta)
      end

      unless options[:api_key]
        config[:api_key] = ask("API Key:", :magenta)
      end

      unless options[:secret_key]
        config[:secret_key] = ask("Secret Key:", :magenta)
      end

      if File.exists? file
        say "Warning: #{file} already exists.", :red
        exit unless yes?("Overwrite [y/N]", :red)
      end
      File.open(file, 'w+') {|f| f.write(config.to_yaml) }
    end    

    desc "command COMMAND [arg1=val1 arg2=val2...]", "run a custom api command"
    def command(command, *args)
      client = CloudstackCli::Helper.new(options[:config])
      params = {'command' => command}
      args.each do |arg|
        arg = arg.split('=')
        params[arg[0]] = arg[1] 
      end
      puts JSON.pretty_generate(client.cs.send_request params)
    end
    
    desc "zone SUBCOMMAND ...ARGS", "Manage zones"
    subcommand "zone", Zone

    desc "project SUBCOMMAND ...ARGS", "Manage servers"
    subcommand "project", Project

    desc "server SUBCOMMAND ...ARGS", "Manage servers"
    subcommand "server", Server

    desc "offering SUBCOMMAND ...ARGS", "Manage offerings"
    subcommand "offering", Offering

    desc "network SUBCOMMAND ...ARGS", "Manage networks"
    subcommand "network", Network

    desc "physical_network SUBCOMMAND ...ARGS", "Manage physical networks"
    subcommand "physical_network", PhysicalNetwork

    desc "load_balancer SUBCOMMAND ...ARGS", "Manage load balancing rules"
    subcommand "load_balancer", LoadBalancer

    desc "template SUBCOMMAND ...ARGS", "Manage template"
    subcommand "template", Template

    desc "router SUBCOMMAND ...ARGS", "Manage virtual routers"
    subcommand "router", Router

    desc "volume SUBCOMMAND ...ARGS", "Manage volumes"
    subcommand "volume", Volume

    desc "stack SUBCOMMAND ...ARGS", "Manage stacks"
    subcommand "stack", Stack

    desc "account SUBCOMMAND ...ARGS", "Manage accounts"
    subcommand "account", Account

    desc "domain SUBCOMMAND ...ARGS", "Manage domains"
    subcommand "domain", Domain

    desc "ip_address SUBCOMMAND ...ARGS", "Manage ip addresses"
    subcommand "ip_address", IpAddress

    desc "capacity SUBCOMMAND ...ARGS", "Lists all the system wide capacities"
    subcommand "capacity", Capacity

    desc "port_rules SUBCOMMAND ...ARGS", "Manage portforwarding rules"
    subcommand "port_rule", PortRule
  end
end