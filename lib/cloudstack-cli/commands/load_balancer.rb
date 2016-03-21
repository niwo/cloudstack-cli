class LoadBalancer < CloudstackCli::Base

  desc "list", "list load balancer rules"
  option :project
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_project
    rules = client.list_load_balancer_rules(options)
    if rules.size < 1
      puts "No load balancer rules found."
    else
      case options[:format].to_sym
      when :yaml
        puts({rules: rules}.to_yaml)
      when :json
        puts JSON.pretty_generate(rules: rules)
      else
        table = [%w(Name Public-IP Public-Port Private-Port Algorithm)]
        rules.each do |rule|
          table << [
            rule['name'],
            rule['publicip'],
            rule['publicport'],
            rule['privateport'],
            rule['algorithm']
          ]
        end
        print_table table
        say "Total number of rules: #{rules.count}"
      end
    end
  end

  desc "create NAME", "create load balancer rule"
  option :project
  option :ip, required: true
  option :public_port, required: true
  option :private_port
  option :algorithm,
    enum: %w(source roundrobin leastconn),
    default: "roundrobin"
  option :open_firewall, type: :boolean
  option :cidr_list
  option :protocol
  def create(name)
    resolve_project
    ip_options = {ip_address: options[:ip]}
    ip_options[:project_id] = options[:project_id] if options[:project_id]
    unless ip = client.list_public_ip_addresses(ip_options).first
      say "Error: IP #{options[:ip]} not found.", :red
      exit 1
    end
    options[:private_port] = options[:public_port] if options[:private_port] == nil
    options[:name] = name
    options[:publicip_id] = ip['id']
    say "Create rule #{name}...", :yellow
    rule = client.create_load_balancer_rule(options)
    say " OK!", :green
  end

  desc "add LB-NAME", "assign servers to balancer rule"
  option :servers,
    required: true,
    type: :array,
    desc: "server names"
  option :project
  def add(name)
    resolve_project
    default_args = options.dup
    default_args.delete(:servers)

    servers = options[:servers].map do |server|
      client.list_virtual_machines(default_args.merge(name: server)).first
    end.compact

    unless servers.size > 0
      say "No servers found with the following name(s): #{options[:servers].join(', ')}", :yellow
      exit 1
    end

    unless rule = client.list_load_balancer_rules(default_args.merge(name: name)).first
      say "Error: LB rule with name #{name} not found.", :red
      exit 1
    end

    say "Add #{servers.map{|s| s['name']}.join(', ')} to rule #{name} ", :yellow
    lb = client.assign_to_load_balancer_rule(
      {
        id: rule['id'],
        virtualmachine_ids: servers.map{|s| s['id']}.join(',')
      }.merge(default_args)
    )

    if lb['success']
      say " OK.", :green
    else
      say " Failed.", :red
    end
  end
end
