module CloudstackCli
  trap("TERM") { puts "SIGTERM received"; exit }

  class Cli < Thor
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
        say "What's the URL of your Cloudstack API?", :blue
        say "Example: https://my-cloudstack-server/client/api/", :blue
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
    
    desc "zone SUBCOMMAND ...ARGS", "manage zones"
    subcommand "zone", Zone

    desc "project SUBCOMMAND ...ARGS", "manage servers"
    subcommand "project", Project

    desc "server SUBCOMMAND ...ARGS", "manage servers"
    subcommand "server", Server

    desc "offering SUBCOMMAND ...ARGS", "manage offerings"
    subcommand "offering", Offering

    desc "network SUBCOMMAND ...ARGS", "manage networks"
    subcommand "network", Network

    desc "lb SUBCOMMAND ...ARGS", "manage load balancing rules"
    subcommand "lb", Lb

    desc "template SUBCOMMAND ...ARGS", "manage template"
    subcommand "template", Template

    desc "router SUBCOMMAND ...ARGS", "manage virtual routers"
    subcommand "router", Router

    desc "router SUBCOMMAND ...ARGS", "manage virtual routers"
    subcommand "router", Router

    desc "volume SUBCOMMAND ...ARGS", "manage volumes"
    subcommand "volume", Volume

    desc "stack SUBCOMMAND ...ARGS", "manage stacks"
    subcommand "stack", Stack

    desc "account SUBCOMMAND ...ARGS", "manage accounts"
    subcommand "account", Account

    desc "domain SUBCOMMAND ...ARGS", "manage domains"
    subcommand "domain", Domain

    desc "publicip SUBCOMMAND ...ARGS", "manage public ip addresses"
    subcommand "publicip", Publicip
  end
end