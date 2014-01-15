class DiskOffer < CloudstackCli::Base

  desc 'list', 'list disk offerings'
  option :domain
  def list
    offerings = client.list_disk_offerings(options[:domain])
    if offerings.size < 1
      puts "No offerings found."
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