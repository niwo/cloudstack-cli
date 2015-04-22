class Zone < CloudstackCli::Base

  desc "list", "list zones"
  def list
    zones = client.list_zones
    if zones.size < 1
      puts "No projects found"
    else
      table = [%w(Name Network-Type Description)]
      zones.each do |zone|
        table << [
          zone['name'],
          zone['networktype'],
          zone['description']
        ]
      end
    end
    print_table(table)
  end

end
