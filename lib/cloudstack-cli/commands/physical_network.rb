class PhysicalNetwork < CloudstackCli::Base

  desc "physical_network list", "list physical networks"
  option :project
  def list
    project = find_project if options[:project]
    networks = client.list_physical_networks
    zones = client.list_zones
    if networks.size < 1
      puts "No networks found"
    else
      table = [['Name', 'State', 'Zone', 'ID']]
      networks.each do |network|
        table << [
          network["name"],
          network["state"],
          zones.select{|zone| zone['id'] == network["zoneid"]}.first["name"], 
          network["id"]
        ]
      end
      print_table table
    end
  end

end