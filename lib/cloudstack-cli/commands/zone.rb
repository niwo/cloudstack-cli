class Zone < Thor

  desc "list", "list zones"
  def list
    cs_cli = CloudstackCli::Cli.new
    zones = cs_cli.zones
    if zones.size < 1
      puts "No projects found"
    else
      zones.each do |zone|
        puts "#{zone['name']} - #{zone['description']}"
      end
    end
  end

end