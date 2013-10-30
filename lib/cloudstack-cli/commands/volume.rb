class Volume < CloudstackCli::Base

  desc "volume list", "list volumes"
  option :project
  def list
    projectid = find_project['id'] if options[:project]
    volumes = client.list_volumes(projectid)
    if volumes.size < 1
      puts "No volumes found."
    else
      table = [["Name", "Type", "Size", "VM", "Storage", "Offeringname"]]
      volumes.each do |volume|
        table << [volume['name'], volume['type'],
          (volume['size'] / 1024**3).to_s + 'GB',
          volume['vmname'],
          volume['storage'], volume['diskofferingname']]
      end
      print_table(table)
    end
  end

end