class Network < CloudstackCli::Base

  desc "create NAME", "create network"
  def create(name)
    # TODO
  end

  desc "list", "list networks"
  option :project
  option :account, default: ""
  def list
    project = find_project if options[:project]

    networks = []
    if project
      networks = client.list_networks(project['id'])
    else
      networks = client.list_networks(-1, options[:account] != '' ? options[:account] : nil )
      networks + client.list_networks(nil, options[:account] != '' ? options[:account] : nil )
    end

    if networks.size < 1
      puts "No networks found"
    else
      table = [["Name", "Displaytext", "Account", "Project", "State", "ID"]]
      networks.each do |network|
        table << [
          network["name"],
          network["displaytext"],
          network["account"],
          network["project"],
          network["state"],
          network["id"]
        ]
      end
      print_table table
    end
  end

end