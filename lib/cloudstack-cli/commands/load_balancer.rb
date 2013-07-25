class Lb < CloudstackCli::Base
  
  desc "list", "list load balancer rules"
  option :project
  def list
    project = find_project if options[:project]
    rules = client.list_load_balancer_rules(
      { project_name: project ? project['name'] : nil }
    )
    if rules.size < 1
      puts "No load balancer rules found"
    else
      table = [["Name", "Public-IP", "Public-Port"]]
      rules.each do |rule|
        table << [rule['name'], rule['publicip'], rule['publicport']]
      end
      print_table table
    end
  end

  desc "create NAME", "create load balancer rule"
  option :project
  option :ip, required: true
  option :public_port, required: true
  option :private_port
  def create(name)
    project = find_project
    options[:private_port] = options[:public_port] if options[:private_port] == nil
    say "Create rule #{name}...", :yellow
    rule = client.create_load_balancer_rule(
      name,
      options[:ip],
      options[:private_port],
      options[:public_port],
    )
    say "OK!", :green
  end

  desc "add NAME", "assign servers to balancer rule"
  option :servers, required: true, type: :array, description: 'server names'
  def add(name)
    say "Add #{names.join(', ')} to rule #{id}...", :yellow
    rule = client.assign_to_load_balancer_rule(
      name,
      options[:servers],
    )
    if rule['success']
      say "OK!", :green
    else
      say "Failed!", :red
    end
  end
end