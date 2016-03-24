class DiskOffer < CloudstackCli::Base

  desc 'list', 'list disk offerings'
  option :domain, desc: "the domain of the disk offering"
  option :format, default: "table",
    enum: %w(table json yaml)
  option :filter, type: :hash,
    desc: "filter objects based on arrtibutes: (attr1:regex attr2:regex ...)"
  def list
    resolve_domain
    add_filters_to_options("listDiskOfferings") if options[:filter]
    offerings = client.list_disk_offerings(options)
    offerings = filter_objects(offerings) if options[:filter]
    if offerings.size < 1
      puts "No offerings found."
    else
      case options[:format].to_sym
      when :yaml
        puts({disk_offers: offerings}.to_yaml)
      when :json
        puts JSON.pretty_generate(disk_offers: offerings)
      else
        table = [["Name", "Displaytext", "Domain", "ID"]]
        offerings.each do |offering|
          table << [
            offering["name"],
            offering["displaytext"],
            offering["domain"],
            offering["id"]
          ]
        end
        print_table table
        say "Total number of offerings: #{offerings.size}"
      end
    end
  end
end
