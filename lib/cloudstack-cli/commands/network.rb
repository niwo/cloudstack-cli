class Network < Thor
  desc "list", "list networks"
  option :project
  def list
    cs_cli = CloudstackCli::Cli.new
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      raise "Project '#{options[:project]}' not found" unless project
    end
    
    networks = cs_cli.networks(project ? project['id'] : nil)
    if networks.size < 1
      puts "No networks found"
    else
      networks.each do |network|
        puts "#{network['name']} - #{network['displaytext']} #{' - Default' if network['isdefault']}"
      end
    end
  end
end