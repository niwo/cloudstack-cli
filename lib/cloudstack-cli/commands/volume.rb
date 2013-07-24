class Volume < CloudstackCli::Base

  desc "list", "list networks"
  option :project
  def list
    if options[:project]
      project = client.list_projects.select { |p| p['name'] == options[:project] }.first
      raise "Project '#{options[:project]}' not found" unless project
    end
    
    networks = client.list_networks(project ? project['id'] : nil)
    if networks.size < 1
      puts "No networks found"
    else
      table = [["Name", "Displaytext", "Default?"]]
      networks.each do |network|
        table << [network['name'], network['displaytext'], network['isdefault']]
      end
      print_table(table)
    end
  end

end