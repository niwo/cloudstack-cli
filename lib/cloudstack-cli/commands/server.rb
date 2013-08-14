class Server < CloudstackCli::Base

  desc "list", "list servers"
  option :project
  option :account
  def list
    if options[:project]
      if options[:project].downcase == "all"
        options[:project_id] = -1
      else
        project = find_project
        options[:project_id] = project['id']
      end
    end
    servers = client.list_servers(options)
    if servers.size < 1
      puts "No servers found."
    else
      table = [["Name", "State", "Offering", "Zone", options[:project] ? "Project" : "Account", "IP's"]]
      servers.each do |server|
        table << [
          server['name'],
          server['state'],
          server['serviceofferingname'],
          server['zonename'],
          options[:project] ? server['project'] : server['account'],
          server['nic'].map { |nic| nic['ipaddress']}.join(' ')
        ]
      end
      print_table table
    end
  end

  desc "create NAME [NAME2 ...]", "create server(s)"
  option :template, aliases: '-t', desc: "name of the template"
  option :iso, desc: "name of the iso", desc: "name of the iso template"
  option :offering, aliases: '-o', required: true, desc: "computing offering name"
  option :networks, aliases: '-n', type: :array, desc: "network names"
  option :zone, aliases: '-z', desc: "availability zone name"
  option :project, aliases: '-p', desc: "project name"
  option :port_rules, aliases: '-pr', type: :array,
    default: [],
    desc: "Port Forwarding Rules [public_ip]:port ..."
  option :disk_offering, desc: "disk offering - data disk for template, root disk for iso"
  option :disk_size, desc: "disk size in GB"
  option :hypervisor, desc: "only used for iso deployments, default: vmware"
  option :keypair, desc: "the name of the ssh keypair to use"
  option :group, desc: "group name"
  def create(name)
    bootstrap_server(options.merge({name: name}))
  end

  desc "destroy NAME [NAME2 ..]", "destroy server(s)"
  option :project
  option :force, description: "destroy without asking", type: :boolean, aliases: '-f'
  def destroy(*names)
    projectid = find_project['id'] if options[:project]
    names.each do |name|
      server = client.get_server(name, projectid)
      unless server
        say "Server #{name} not found.", :red
      else
        ask = "Destroy #{name} (#{server['state']})?"
        if options[:force] || yes?(ask, :yellow)
          say "destroying #{name} "
          client.destroy_server(server["id"])
          puts  
        end
      end
    end
  end

  desc "bootstrap", "interactive creation of a server with network access"
  def bootstrap
    bootstrap_server_interactive
  end

  desc "stop NAME", "stop a server"
  def stop(name)
    client.stop_server(name)
    puts
  end

  desc "start NAME", "start a server"
  def start(name)
    client.start_server(name)
    puts
  end

  desc "reboot NAME", "reboot a server"
  def restart(name)
    client.reboot_server(name)
    puts
  end

end