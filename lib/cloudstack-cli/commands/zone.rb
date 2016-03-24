class Zone < CloudstackCli::Base

  desc "list", "list zones"
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    zones = client.list_zones
    if zones.size < 1
      puts "No projects found"
    else
      case options[:format].to_sym
      when :yaml
        puts({zones: zones}.to_yaml)
      when :json
        puts JSON.pretty_generate(zones: zones)
      else
        table = [%w(Name Network-Type Description)]
        zones.each do |zone|
          table << [
            zone['name'],
            zone['networktype'],
            zone['description']
          ]
        end
        print_table(table)
      end
    end
  end

end
