module CloudstackCli
  class Cli < CloudstackCli::Base
    include Thor::Actions

    package_name "cloudstack-cli" 

    class_option :config_file,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-e',
      desc: 'environment to use'

    class_option :debug,
      desc: 'enable debug output',
      type: :boolean

    desc "version", "print cloudstack-cli version number"
    def version
      say "cloudstack-cli version #{CloudstackCli::VERSION}"
    end
    map %w(-v --version) => :version

    desc "setup", "initial configuration of Cloudstack connection settings"
    def setup(env = options[:environment])
      invoke "environment:add", [env],
        :config_file => options[:config_file]
    end

    desc "completion", "loads the shell scripts for <tab> auto-completion"
    option :shell, default: 'bash'
    def completion
      shell_script = File.join(
        File.dirname(__FILE__), '..', '..',
        'completions', "cs.#{options[:shell]}"
      )
      unless File.file? shell_script
        say "Specified cloudstack-cli shell auto-completion rules for #{options[:shell]} not found.", :red
        exit 1
      end
      puts File.read shell_script
    end

    desc "command COMMAND [arg1=val1 arg2=val2...]", "run a custom api command"
    def command(command, *args)
      params = {'command' => command}
      args.each do |arg|
        arg = arg.split('=')
        params[arg[0]] = arg[1] 
      end
      data = client.send_request(params)
      puts JSON.pretty_generate(data)
    end

    # require subcommands
    Dir[File.dirname(__FILE__) + '/commands/*.rb'].each do |command| 
      require command
    end

    desc "environment SUBCOMMAND ...ARGS", "Manage cloudstack-cli environments"
    subcommand :environment, Environment
    map 'env' => :environment
    
    desc "zone SUBCOMMAND ...ARGS", "Manage zones"
    subcommand :zone, Zone

    desc "pod SUBCOMMAND ...ARGS", "List pods"
    subcommand :pod, Pod

    desc "cluster SUBCOMMAND ...ARGS", "List clusters"
    subcommand :cluster, Cluster

    desc "host SUBCOMMAND ...ARGS", "List hosts"
    subcommand :host, Host

    desc "project SUBCOMMAND ...ARGS", "Manage servers"
    subcommand :project, Project

    desc "server SUBCOMMAND ...ARGS", "Manage servers"
    subcommand :server, Server

    desc "compute_offer SUBCOMMAND ...ARGS", "Manage offerings"
    subcommand :compute_offer, ComputeOffer

    desc "disk_offer SUBCOMMAND ...ARGS", "Manage disk offerings"
    subcommand :disk_offering, DiskOffer

    desc "network SUBCOMMAND ...ARGS", "Manage networks"
    subcommand :network, Network
    map 'networks' => 'network'

    desc "physical_network SUBCOMMAND ...ARGS", "Manage physical networks"
    subcommand :physical_network, PhysicalNetwork

    desc "load_balancer SUBCOMMAND ...ARGS", "Manage load balancing rules"
    subcommand :load_balancer, LoadBalancer

    desc "template SUBCOMMAND ...ARGS", "Manage templates"
    subcommand :template, Template

    desc "iso SUBCOMMAND ...ARGS", "Manage iso's"
    subcommand :iso, Iso

    desc "router SUBCOMMAND ...ARGS", "Manage virtual routers"
    subcommand :router, Router

    desc "volume SUBCOMMAND ...ARGS", "Manage volumes"
    subcommand :volume, Volume

    desc "snapshot SUBCOMMAND ...ARGS", "Manage snapshots"
    subcommand :snapshot, Snapshot

    desc "stack SUBCOMMAND ...ARGS", "Manage stacks"
    subcommand :stack, Stack

    desc "account SUBCOMMAND ...ARGS", "Manage accounts"
    subcommand :account, Account

    desc "user SUBCOMMAND ...ARGS", "Manage users"
    subcommand :user, User

    desc "domain SUBCOMMAND ...ARGS", "Manage domains"
    subcommand :domain, Domain

    desc "ip_address SUBCOMMAND ...ARGS", "Manage ip addresses"
    subcommand :ip_address, IpAddress

    desc "capacity SUBCOMMAND ...ARGS", "Lists all the system wide capacities"
    subcommand :capacity, Capacity

    desc "port_rule SUBCOMMAND ...ARGS", "Manage portforwarding rules"
    subcommand :port_rule, PortRule

    desc "job SUBCOMMAND ...ARGS", "Display async jobs"
    subcommand :job, Job

    desc "ssh_key_pair SUBCOMMAND ...ARGS", "Manage ssh key pairs"
    subcommand :ssh_key_pair, SshKeyPair

    desc "storage_pool SUBCOMMAND ...ARGS", "Manage storage pools"
    subcommand :storage_pool, StoragePool

    desc "region SUBCOMMAND ...ARGS", "Manage regions"
    subcommand :region, Region

    desc "affinity_group SUBCOMMAND ...ARGS", "Manage affinity_groups"
    subcommand :affinity_group, AffinityGroup  
  end
end