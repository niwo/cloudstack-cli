class Server < CloudstackCli::Base

  desc "list", "list servers"
  option :project
  option :account
  option :zone
  option :command, desc: "command to execute for each server: START, STOP or RESTART"
  option :status
  option :listall
  def list
    if options[:project]
      project_id = find_project['id']
      options[:project_id] = project_id
    end
    servers = client.list_servers(options)
    if servers.size < 1
      puts "No servers found."
    else
      table = [["Name", "Status", "Offering", "Zone", project_id ? "Project" : "Account", "IP's"]]
      servers.each do |server|
        table << [
          server['name'],
          server['state'],
          server['serviceofferingname'],
          server['zonename'],
          project_id ? server['project'] : server['account'],
          server['nic'].map { |nic| nic['ipaddress']}.join(' ')
        ]
      end
      print_table table
      say "Total number of servers: #{servers.count}"

      if options[:command]
        args = { project_id: project_id, sync: true, account: options[:account] }
        case options[:command].downcase
          when "start"
            exit unless yes?("\nStart the server(s) above? [y/N]:", :magenta)
            jobs = servers.map do |server|
              {id: client.start_server(server['name'], args)['jobid'], name: "Start server #{server['name']}"}
            end
          when "stop"
            exit unless yes?("\nStop the server(s) above? [y/N]:", :magenta)
            jobs = servers.map do |server|
              {id: client.stop_server(server['name'], args)['jobid'], name: "Stop server #{server['name']}"}
            end
          when "restart"
            exit unless yes?("\nRestart the server(s) above? [y/N]:", :magenta)
            jobs = servers.map do |server|
              {id: client.reboot_server(server['name'], args)['jobid'], name: "Restart server #{server['name']}"}
            end
          else
            say "\nCommand #{options[:command]} not supported.", :red
            exit 1
          end
          puts
          watch_jobs(jobs)
        end
      end
  end

  desc "show NAME", "show detailed infos about a server"
  option :project
  def show(name)
    options[:project_id] = find_project['id']
    unless server = client.get_server(name, options)
      puts "No server found."
    else
      server.each do |key, value|
        say "#{key}: ", :yellow
        say "#{value}"
      end
    end
  end

  desc "create NAME [NAME2 ...]", "create server(s)"
  option :template, aliases: '-t', desc: "name of the template"
  option :iso, desc: "name of the iso", desc: "name of the iso template"
  option :offering, aliases: '-o', required: true, desc: "computing offering name"
  option :zone, aliases: '-z', required: true, desc: "availability zone name"
  option :networks, aliases: '-n', type: :array, desc: "network names"
  option :project, aliases: '-p', desc: "project name"
  option :port_rules, aliases: '-pr', type: :array,
    default: [],
    desc: "Port Forwarding Rules [public_ip]:port ..."
  option :disk_offering, desc: "disk offering - data disk for template, root disk for iso"
  option :disk_size, desc: "disk size in GB"
  option :hypervisor, desc: "only used for iso deployments, default: vmware"
  option :keypair, desc: "the name of the ssh keypair to use"
  option :group, desc: "group name"
  option :account, desc: "account name"
  def create(*names)
    projectid = find_project['id'] if options[:project]
    say "Start deploying servers...", :green
    jobs = names.map do |name|
      server = client(quiet: true).get_server(name, project_id: projectid)
      if server
        say "Server #{name} (#{server["state"]}) already exists.", :yellow
        job = {
          id: 0,
          name: "Create server #{name}",
          status: 1
        }
      else
        job = {
          id: client.create_server(options.merge({name: name, sync: true}))['jobid'],
          name: "Create server #{name}"
        }
      end
      job
    end
    watch_jobs(jobs)
    if options[:port_rules].size > 0
      say "Create port forwarding rules...", :green
      jobs = []
      names.each do |name|
        server = client(quiet: true).get_server(name, project_id: projectid)
        create_port_rules(server, options[:port_rules], false).each_with_index do |job_id, index|
          jobs << {
            id: job_id,
            name: "Create port forwarding ##{index + 1} rules for server #{server['name']}"
          }
        end
      end
      watch_jobs(jobs)
    end
    say "Finished.", :green
  end

  desc "destroy NAME [NAME2 ..]", "destroy server(s)"
  option :project
  option :force, description: "destroy without asking", type: :boolean, aliases: '-f'
  def destroy(*names)
    projectid = find_project['id'] if options[:project]
    names.each do |name|
      server = client.get_server(name, project_id: projectid)
      unless server
        say "Server #{name} not found.", :red
      else
        ask = "Destroy #{name} (#{server['state']})? [y/N]:"
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
  option :project
  option :account
  option :force
  def stop(name)
    options[project_id] = find_project['id'] if options[:project]
    exit unless options[:force] || yes?("Stop server #{name}? [y/N]:", :magenta)
    client.stop_server(name, options)
    puts
  end

  desc "start NAME", "start a server"
  option :project
  option :account
  def start(name)
    options[project_id] = find_project['id'] if options[:project]
    say("Start server #{name}", :magenta)
    client.start_server(name, options)
    puts
  end

  desc "reboot NAME", "reboot a server"
  option :project
  option :account
  option :force
  def restart(name)
    options[project_id] = find_project['id'] if options[:project]
    exit unless options[:force] || yes?("Reboot server #{name}? [y/N]:", :magenta)
    client.reboot_server(name, options)
    puts
  end

end