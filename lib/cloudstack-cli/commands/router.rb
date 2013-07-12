require 'command_line_reporter'

class Router < Thor
	include CommandLineReporter

	desc "list", "list virtual routers"
  option :project
  option :listall
  def list
		cs_cli = CloudstackCli::Cli.new
   	if options[:project]
    	project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
     	raise "Project '#{options[:project]}' not found" unless project
     	projectid = project['id']
   	end

		routers = cs_cli.list_routers({projectid: projectid})
			if options[:listall]
			projects = cs_cli.projects
			projects.each do |project|
		  	routers = routers + cs_cli.list_routers({projectid: project['id']})
		  end
		end

	  puts "Total number of routers: #{routers.size}"

		table(border: true) do
    	row do
        column 'Name'
        column 'Zone'
        column 'Account', width: 14 unless options[:project]
        column 'Project', width: 14 if options[:listall] || options[:project]
        column 'Redundant State'
        column 'Public IP', width: 15
      end
      routers.each do |router|
        row do
          column router["name"]
          column router["zonename"]
          column router["account"] unless options[:project]
          column router["project"] if options[:listall] || options[:project]
          column router["redundantstate"]
          column router["publicip"]
        end
      end
    end

  end

  desc "stop NAME", "stop virtual router"
  option :project

  def stopall

  end

  desc "start NAME", "start virtual router"
  option :project
  def start

  end

end