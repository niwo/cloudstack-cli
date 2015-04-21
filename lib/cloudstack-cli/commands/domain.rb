class Domain < CloudstackCli::Base

  desc 'list', 'list domains'
  def list
    domains = client.list_domains
    if domains.size < 1
      puts "No domains found."
    else
      table = [["Name", "Path"]]
      domains.each do |domain|
        table << [domain['name'], domain['path']]
      end
      print_table table
      say "Total number of domains: #{domains.size}"
    end
  end

end
