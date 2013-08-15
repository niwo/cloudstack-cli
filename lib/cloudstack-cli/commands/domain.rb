class Domain < CloudstackCli::Base

  desc 'list [NAME]', 'list domains'
  def list(name = nil)
    domains = client.list_domains(name)
    if domains.size < 1
      puts "No domains found."
    else
      table = [["Name", "Path"]]
      domains.each do |domain|
        table << [domain['name'], domain['path']]
      end
      print_table table
    end
  end
  
end