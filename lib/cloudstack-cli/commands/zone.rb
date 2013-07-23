class Zone < Thor

  desc "zone list", "list zones"
  def list
    cs_cli = CloudstackCli::Helper.new(options[:config])
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