class Server < Thor

  desc "server list", "list servers"
  option :listall, :type => :boolean
  option :text, :type => :boolean
  option :project
  option :account
  def list
    cs_cli = CloudstackCli::Helper.new(options[:config])
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
      options[:project_id] = project['id']
      options[:account] = nil
    end
    servers = cs_cli.virtual_machines(options)
    if servers.size < 1
      puts "No servers found"
    else
      if options[:text]
        servers.each do |server|
          puts "#{server['name']} - #{server['state']} - #{server['domain']}"
        end
      else
        cs_cli.virtual_machines_table(servers)
      end
    end
  end

  desc "server create NAME", "create a server"
  option :zone, :required => true
  option :template, :required => true
  option :offering, :required => true
  option :networks, :type => :array, :required => true
  option :project
  option :port_forwarding, :type => :array, :aliases => :pf, :default => [], :description => "public_ip:port"
  option :interactive, :type => :boolean
  def create(name)
    CloudstackCli::Helper.new(options[:config]).bootstrap_server(
        name,
        options[:zone],
        options[:template],
        options[:offering],
        options[:networks],
        options[:port_forwarding],
        options[:project]
      )
  end

  desc "server bootstrap", "interactive creation of a server with network access"
  def bootstrap
    CloudstackCli::Helper.new(options[:config]).bootstrap_server_interactive()
  end

  desc "server stop NAME", "stop a server"
  def stop(name)
    CloudstackCli::Helper.new(options[:config]).stop_server(name)
  end

  desc "server start NAME", "start a server"
  def start(name)
    CloudstackCli::Helper.new(options[:config]).start_server(name)
  end

  desc "server reboot NAME", "reboot a server"
  def restart(name)
    CloudstackCli::Helper.new(options[:config]).reboot_server(name)
  end

end