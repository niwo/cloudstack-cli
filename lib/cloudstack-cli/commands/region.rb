class Region < CloudstackCli::Base

  desc 'list', 'list regions'
  def list
    regions = client.list_regions
    if regions.size < 1
      say "No regions found."
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