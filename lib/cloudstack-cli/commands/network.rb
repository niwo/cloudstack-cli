class Network < Thor
  include CommandLineReporter

  desc "create NAME", "create network"
  def create(name)


  end

  desc "list", "list networks"
  option :project
  option :physical, type: :boolean
  def list
    cs_cli = CloudstackCli::Helper.new
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      raise "Project '#{options[:project]}' not found" unless project
    end
    
    if options[:physical]
      networks = cs_cli.physical_networks

      if networks.size < 1
        puts "No networks found"
      else
        table(border: true) do
          row do
            column 'ID', width: 40
            column 'Name', width: 30
            column 'Zone ID', width: 14 unless options[:project]
            column 'State'
          end
          networks.each do |network|
            row do
              column network["id"]
              column network["name"]
              column network["zoneid"]
              column network["state"]
            end
          end
        end
      end
    else
      networks = cs_cli.networks(project ? project['id'] : -1)

      if networks.size < 1
        puts "No networks found"
      else
        table(border: true) do
          row do
            column 'ID', width: 40
            column 'Name', width: 30
            column 'Displaytext', width: 30
            column 'Account', width: 14 unless options[:project]
            column 'Project', width: 14 if options[:listall] || options[:project]
            column 'State'
          end
          networks.each do |network|
            row do
              column network["id"]
              column network["name"]
              column network["displaytext"]
              column network["account"] unless options[:project]
              column network["project"] if options[:listall] || options[:project]
              column network["state"]
            end
          end
        end
      end
    end

    
  end
end