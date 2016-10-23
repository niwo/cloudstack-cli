class PortRule < CloudstackCli::Base

  desc "create VM-NAME", "create portforwarding rules for a given VM"
  option :rules, type: :array,
    required: true,
    desc: "Port Forwarding Rules [public_ip]:port ...",
    aliases: '-r'
  option :network, required: true, aliases: '-n'
  option :project
  option :keyword, desc: "list by keyword"
  def create(server_name)
    resolve_project
    unless server = client.list_virtual_machines(
      name: server_name, project_id: options[:project_id], listall: true
      ).find {|vm| vm["name"] == server_name }
      error "Server #{server_name} not found."
      exit 1
    end
    ip_addr = nil
    options[:rules].each do |pf_rule|
      ip = pf_rule.split(":")[0]
      unless ip == ''
        unless ip_addr = client.list_public_ip_addresses(ipaddress: ip, project_id: options[:project_id]).first
          say "Error: IP #{ip} not found.", :yellow
          next
        end
      else
        say "Assign a new IP address ", :yellow
        net_id = client.list_networks(project_id: options[:project_id]).find {|n| n['name'] == options[:network]}['id']
        say(" OK", :green) if ip_addr = client.associate_ip_address(networkid: net_id)["ipaddress"]
      end
      port = pf_rule.split(":")[1]
      say "Create port forwarding rule #{ip_addr["ipaddress"]}:#{port} for server #{server_name} ", :yellow

      say(" OK", :green) if client.create_port_forwarding_rule(
        ipaddress_id: ip_addr["id"],
        public_port: port,
        private_port: port,
        virtualmachine_id: server["id"],
        protocol: "TCP"
      )
    end
  end

  desc "list", "list portforwarding rules"
  option :project
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_project
    rules = client.list_port_forwarding_rules(options)
    if rules.size < 1
      puts "No rules found."
    else
      case options[:format].to_sym
      when :yaml
        puts({rules: rules}.to_yaml)
      when :json
        puts JSON.pretty_generate(rules: rules)
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
