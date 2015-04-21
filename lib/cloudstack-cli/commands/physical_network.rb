class PhysicalNetwork < CloudstackCli::Base

  desc "list", "list physical networks"
  option :project
  def list
    resolve_project
    networks = client.list_physical_networks(options)
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
      say "Total number of networks: #{networks.count}"
    end
  end

end
