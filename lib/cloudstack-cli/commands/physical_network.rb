class PhysicalNetwork < CloudstackCli::Base

  desc "list", "list physical networks"
  option :project
  def list
    project = find_project if options[:project]
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
  end

end