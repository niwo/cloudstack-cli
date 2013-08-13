module CloudstackCli
  class Cli < CloudstackCli::Base
    include Thor::Actions

    package_name "cloudstack-cli" 
    map %w(-v --version) => :version 

    class_option :config,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'location of your cloudstack-cli configuration file'

    class_option :environment,
      aliases: '-e',
      desc: 'environment to load from the configuration file'

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
        say "Configuring #{options[:environment] || 'default'} environment."
        say "What's the URL of your Cloudstack API?", :yellow
        say "Example: https://my-cloudstack-service/client/api/"
        config[:url] = ask("URL:", :magenta)
      end
      unless options[:api_key]
        config[:api_key] = ask("API Key:", :magenta)
      end
      unless options[:secret_key]
        config[:secret_key] = ask("Secret Key:", :magenta)
      end
      if options[:environment]
        config = {options[:environment] => config}
      end
      if File.exists? file
        begin
          old_config = YAML::load(IO.read(file))
        rescue
          error "Can't load configuration from file #{config_file}."
          exit 1
        end
        say "Warning: #{file} already exists.", :red
        exit unless yes?("Do you want to merge your settings? [y/N]", :red)
        config = old_config.merge(config)
      end
      File.open(file, 'w+') {|f| f.write(config.to_yaml) }
    end    

    desc "command COMMAND [arg1=val1 arg2=val2...]", "run a custom api command"
    def command(command, *args)
      params = {'command' => command}
      args.each do |arg|
        arg = arg.split('=')
        params[arg[0]] = arg[1] 
      end
      puts JSON.pretty_generate(client.send_request params)
    end

    # require subcommands
    Dir[File.dirname(__FILE__) + '/commands/*.rb'].each do |command| 
      require command
    end
    
    desc "zone SUBCOMMAND ...ARGS", "Manage zones"
    subcommand "zone", Zone

    desc "project SUBCOMMAND ...ARGS", "Manage servers"
    subcommand "project", Project

    desc "server SUBCOMMAND ...ARGS", "Manage servers"
    subcommand "server", Server

    desc "offering SUBCOMMAND ...ARGS", "Manage offerings"
    subcommand "offering", Offering

    desc "disk_offering SUBCOMMAND ...ARGS", "Manage disk offerings"
    subcommand "disk_offering", DiskOffering

    desc "network SUBCOMMAND ...ARGS", "Manage networks"
    subcommand "network", Network

    desc "physical_network SUBCOMMAND ...ARGS", "Manage physical networks"
    subcommand "physical_network", PhysicalNetwork

    desc "load_balancer SUBCOMMAND ...ARGS", "Manage load balancing rules"
    subcommand "load_balancer", LoadBalancer

    desc "template SUBCOMMAND ...ARGS", "Manage templates"
    subcommand "template", Template

    desc "iso SUBCOMMAND ...ARGS", "Manage iso's"
    subcommand "iso", Iso

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