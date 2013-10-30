class Network < CloudstackCli::Base

  desc "network list", "list networks"
  option :project
  option :account
  option :showid, type: :boolean
  option :isdefault, type: :boolean
  def list
    project = find_project if options[:project]
    networks = []
    if project
      networks = client.list_networks(project_id: project['id'])
    elsif options[:account]
      networks = client.list_networks(account: options[:account])
    else
      networks = client.list_networks(isdefault: options[:isdefault])
      networks += client.list_networks(project_id: -1, isdefault: options[:isdefault])
    end

    if networks.size < 1
      puts "No networks found."
    else
      table = [["Name", "Displaytext", "Account", "Project", "Domain", "State", "Type"]]
      table[0] << "ID" if options[:showid]
      networks.each do |network|
        table << [
          network["name"],
          network["displaytext"],
          network["account"],
          network["project"],
          network["domain"],
          network["state"],
          network["type"]
        ]
        table[-1] << network["id"] if options[:showid]
      end
      print_table table
    end
  end

  desc "network default", "get the default network"
  option :zone
  def default
    network = client.get_default_network(options[:zone])
    unless network
      puts "No default network found."
    else
      table = [["Name", "Displaytext", "Domain", "Zone"]]
      table[0] << "ID" if options[:showid]
        table << [
          network["name"],
          network["displaytext"],
          network["domain"],
          network["zonename"]
        ]
        table[-1] << network["id"] if options[:showid]
      print_table table
    end
  end

  desc "network show NAME", "show detailed infos about a network"
  option :project
  def show(name)
    if options[:project]
      if options[:project].downcase == "all"
        options[:project_id] = -1
      else
        project = find_project
        options[:project_id] = project['id']
      end
    end
    unless server = client.get_network(name, options[:project_id])
      puts "No network found."
    else
      server.each do |key, value|
        say "#{key}: ", :yellow
        say "#{value}"
      end
    end
  end

  desc "network restart NAME", "restart network"
  option :cleanup, type: :boolean, default: true
  def restart(name)
    network = client.get_network(name)
    network = client.get_network(name, -1) unless network
    unless network
      say "Network #{name} not found."
      exit 1
    end
    if yes? "Restart network \"#{network['name']}\" (cleanup=#{options[:cleanup]})?"
      p client.restart_network(network['id'], options[:cleanup])
    end
  end

  desc "network delete NAME", "delete network"
  def delete(name)
    network = client.get_network(name)
    network = client.get_network(name, -1) unless network
    unless network
      say "Network \"#{name}\" not found."
      exit 1
    end
    if yes? "Destroy network \"#{network['name']}\"?"
      p client.delete_network(network['id'])
    end
  end

end