class PortRule < CloudstackCli::Base

  desc "create SERVER", "create portforwarding rules"
  option :rules, type: :array,
    required: true,
    desc: "Port Forwarding Rules [public_ip]:port ...",
    aliases: '-r'
  option :network, required: true, aliases: '-n'
  option :project
  def create(server_name)
    projectid = find_project['id'] if options[:project]
    unless server = client.get_server(server_name, projectid)
      error "Server #{server_name} not found."
      exit 1
    end
    frontendip = nil
    options[:rules].each do |pf_rule|
      ip = pf_rule.split(":")[0]
      if ip != ''
        ip_addr = client.get_public_ip_address(ip, projectid)
        unless ip_addr
          say "Error: IP #{ip} not found.", :red
          next
        end
      else
        ip_addr = frontendip ||= client.associate_ip_address(
          client.get_network(options[:network], projectid)
        )
      end
      port = pf_rule.split(":")[1]
      puts
      say "Create port forwarding rule #{ip_addr["ipaddress"]}:#{port} for server #{server_name}.", :yellow
      client.create_port_forwarding_rule(ip_addr["id"], port, 'TCP', port, server["id"])
      puts
    end
  end

  desc "list", "list portforwarding rules"
  option :project
  def list
    project_id = find_project['id'] if options[:project]
    rules = client.list_port_forwarding_rules(ip_address_id=nil, project_id)
    if rules.size < 1
      puts "No rules found."
    else
      table = [["IP", "Server", "Public-Port", "Private-Port", "Protocol", "State"]]
      rules.each do |rule|
        table << [
          rule['ipaddress'],
          rule['virtualmachinename'],
          print_ports(rule, 'public'),
          print_ports(rule, 'private'),
          rule['protocol'],
          rule['state']
        ]
      end
      print_table table
      say "Total number of rules: #{rules.count}"
    end
  end

  no_commands do
    def print_ports(rule, type)
      if rule["#{type}port"] == rule["#{type}endport"]
        return rule["#{type}port"]
      else
        return rule["#{type}port"] + "-" + rule["#{type}endport"]
      end
    end
  end
end