class Volume < CloudstackCli::Base

  desc "list", "list volumes"
  option :project, desc: 'list resources by project'
  option :account, desc: 'list resources by account'
  option :keyword, desc: 'list by keyword'
  option :name, desc: 'name of the disk volume'
  option :type, desc: 'type of disk volume (ROOT or DATADISK)'
  def list
    options[:project_id] = find_project['id']
    volumes = client.list_volumes(options)
    if volumes.size < 1
      say "No volumes found."
    else
      table = [%w(Name Type Size VM Storage Offeringname)]
      volumes.each do |volume|
        table << [
          volume['name'], volume['type'],
          (volume['size'] / 1024**3).to_s + 'GB',
          volume['vmname'],
          volume['storage'],
          volume['diskofferingname']
        ]
      end
      print_table(table)
    end
  end

end