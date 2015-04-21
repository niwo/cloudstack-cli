class Network < CloudstackCli::Base

  desc "list", "list networks"
  option :project, desc: 'the project name of the network'
  option :account, desc: 'the owner of the network'
  option :zone, desc: 'the name of the zone the network belongs to'
  option :type, desc: 'the type of the network'
  option :showid, type: :boolean, desc: 'show the network id'
  option :showvlan, type: :boolean, desc: 'show the VLAN'
  def list
    resolve_zone if options[:zone]
    resolve_project
    networks = client.list_networks(options)

    if networks.size < 1
      puts "No networks found."
    else
      networks = filter_by(networks, 'type', options[:type]) if options[:type]
      table = [%w(Name Displaytext Account/Project Zone Domain State Type Offering)]
      table[0] << "ID" if options[:showid]
      table[0] << "VLAN" if options[:showvlan]
      networks.each do |network|
        table << [
          network["name"],
          network["displaytext"],
          network["account"] || network["project"],
          network["zonename"],
          network["domain"],
          network["state"],
          network["type"],
          network["networkofferingname"]
        ]
        table[-1] << network["id"] if options[:showid]
        table[-1] << network["vlan"] if options[:showvlan]
      end
      print_table table
      say "Total number of networks: #{networks.count}"
    end
  end

  desc "show NAME", "show detailed infos about a network"
  option :project
  def show(name)
    resolve_project
    unless network = client.list_networks(options).find {|n| n['name'] == name}
      say "Error: No network with name '#{name}' found.", :red
      exit
    end
    table = network.map do |key, value|
      [ set_color("#{key}:", :yellow), "#{value}" ]
    end
    print_table table
  end

  desc "restart NAME", "restart network"
  option :cleanup, type: :boolean, default: false
  option :project
  def restart(name)
    resolve_project
    unless network = client.list_networks(options).find {|n| n['name'] == name}
      say "Network with name '#{name}' not found."
      exit 1
    end
    if yes? "Restart network \"#{network['name']}\" (cleanup=#{options[:cleanup]})?"
      client.restart_network(id: network['id'], cleanup: options[:cleanup])
    end
  end

  desc "delete NAME", "delete network"
  option :project
  def delete(name)
    resolve_project
    unless network = client.list_networks(options).find {|n| n['name'] == name}
      say "Error: Network with name '#{name}' not found.", :red
      exit 1
    end
    if yes? "Delete network \"#{network['name']}\"?"
      client.delete_network(id: network['id'])
    end
  end

end
