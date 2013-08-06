class Network < CloudstackCli::Base

  desc "create NAME", "create network"
  def create(name)
    # TODO
  end

  desc "list", "list networks"
  option :project
  option :account
  option :showid, type: :boolean
  def list
    project = find_project if options[:project]
    networks = []
    if project
      networks = client.list_networks(project['id'])
    elsif options[:account]
      networks = client.list_networks(account: options[:account])
    else
      networks = client.list_networks(project_id: -1)
    end

    if networks.size < 1
      puts "No networks found"
    else
      table = [["Name", "Displaytext", "Account", "Project", "Domain", "State"]]
      table[0] << "ID" if options[:showid]
      networks.each do |network|
        table << [
          network["name"],
          network["displaytext"],
          network["account"],
          network["project"],
          network["domain"],
          network["state"]
        ]
        table[-1] << network["id"] if options[:showid]
      end
      print_table table
    end
  end

end