class Network < CloudstackCli::Base

  desc "create NAME", "create network"
  def create(name)
    # TODO
  end

  desc "list", "list networks"
  option :project
  option :physical, type: :boolean
  def list
    project = find_project if options[:project]
    if options[:physical]
      networks = client.list_physical_networks
      if networks.size < 1
        puts "No networks found"
      else
        table = [['Name', 'State', 'ID', 'Zone ID']]
        networks.each do |network|
          table << [
            network["name"],
            network["state"],
            network["id"],
            network["zoneid"] 
          ]
        end
        print_table table
      end
    else
      networks = client.list_networks(project ? project['id'] : -1)
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

end