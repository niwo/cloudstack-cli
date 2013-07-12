class Server < Thor

  desc "list", "list servers"
  option :listall, :type => :boolean
  option :text, :type => :boolean
  option :project
  def list
    cs_cli = CloudstackCli::Cli.new
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
      options[:project_id] = project['id']
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

  desc "create NAME", "create a server"
  option :zone, :required => true
  option :template, :required => true
  option :offering, :required => true
  option :networks, :type => :array, :required => true
  option :project
  option :port_forwarding, :type => :array, :aliases => :pf, :default => [], :description => "public_ip:port"
  option :interactive, :type => :boolean
  def create(name)
    CloudstackCli::Cli.new.bootstrap_server(
        name,
        options[:zone],
        options[:template],
        options[:offering],
        options[:networks],
        options[:port_forwarding],
        options[:project]
      )
  end

  desc "stop NAME", "stop a server"
  def stop(name)
    CloudstackCli::Cli.new.stop_server(name)
  end

  desc "start NAME", "start a server"
  def start(name)
    CloudstackCli::Cli.new.start_server(name)
  end

  desc "reboot NAME", "reboot a server"
  def restart(name)
    CloudstackCli::Cli.new.reboot_server(name)
  end

end