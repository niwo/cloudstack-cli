module CloudstackCli
  class Cli < Thor
    class_option :config
    class_option :verbose, type: :boolean

    desc "command COMMAND [arg1=val1] [arg2=val2]...", "run a custom api command"
    def command(command, *cmds)
      client = CloudstackCli::Helper.new
      params = {'command' => command}
      cmds.each do |cmd|
        cmd = cmd.split('=')
        params[cmd[0]] = cmd[1] 
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