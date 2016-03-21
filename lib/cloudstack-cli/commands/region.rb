class Region < CloudstackCli::Base

  desc 'list', 'list regions'
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    regions = client.list_regions
    if regions.size < 1
      say "No regions found."
    else
      case options[:format].to_sym
      when :yaml
        puts({regions: regions}.to_yaml)
      when :json
        puts JSON.pretty_generate(regions: regions)
      else
        table = [%w(Name, Endpoint)]
        regions.each do |region|
          table << [
          	region['name'], region['endpoint']
          ]
        end
        print_table table
        say "Total number of regions: #{regions.size}"
      end
    end
  end

end
