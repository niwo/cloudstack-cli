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

  desc "create NAME", "create a server"
  option :zone, required: true
  option :template, required: true
  option :offering, required: true
  option :networks, type: :array, required: true
  option :project
  option :port_rules, type: :array,
    default: [],
    desc: "Port Forwarding Rules [public_ip]:port ..."
  option :interactive, type: :boolean
  def create(name)
    CloudstackCli::Helper.new(options[:config]).bootstrap_server(
      name,
      options[:zone],
      options[:template],
      options[:offering],
      options[:networks],
      options[:port_rules],
      options[:project]
    )
  end

  desc "destroy NAME [NAME2 ..]", "destroy a server"
  option :project
  option :force, description: "destroy without asking", type: :boolean, aliases: '-f'
  def destroy(*name)
    projectid = find_project['id'] if options[:project]

    name.each do |server_name|
      server = client.get_server(server_name, projectid)
      unless server
        say "Server #{server_name} not found.", :red
      else
        ask = "Destroy #{server_name} (#{server['state']})?"
        if options[:force] == true || yes?(ask)
          say "Destroying #{server_name} "
          client.destroy_server(server["id"])
          puts  
        end
      end
    end
  end

  desc "bootstrap", "interactive creation of a server with network access"
  def bootstrap
    CloudstackCli::Helper.new(options[:config]).bootstrap_server_interactive()
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