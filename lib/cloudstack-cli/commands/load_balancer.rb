class Lb < Thor
  
  desc "lb list", "list load balancer rules"
  option :project
  def list
    cs_cli = CloudstackCli::Helper.new(options[:config])
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
    end
    
    rules = cs_cli.list_load_balancer_rules(project ? project['id'] : nil)
    if rules.size < 1
      puts "No load balancer rules found"
    else
      rules.each do |rule|
        puts "#{rule['name']} - #{rule['publicip']}:#{rule['publicport']}"
      end
    end
  end

  desc "lb create NAME", "create load balancer rule"
  option :project
  option :ip, :required => true
  option :public_port, :required => true
  option :private_port
  def create(name)
    cs_cli = CloudstackCli::Helper.new(options[:config])
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
    end

    options[:private_port] = options[:public_port] if options[:private_port] == nil
    
    rule = cs_cli.create_load_balancer_rule(
      name,
      options[:ip],
      options[:private_port],
      options[:public_port],
    )
  end

  desc "lb add NAME", "assign servers to balancer rule"
  option :project
  option :servers, required: true, type: :array, description: 'server names'
  def add(name)
    cs_cli = CloudstackCli::Helper.new(options[:config])
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
    end
    
    rule = cs_cli.assign_to_load_balancer_rule(
      name,
      options[:servers],
    )
  end
end