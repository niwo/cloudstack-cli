class Router < Thor
	desc "list", "list virtual routers"
  	option :project
  	def list
	  	cs_cli = CloudstackCli::Cli.new
   	if options[:project]
     project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
     raise "Project '#{options[:project]}' not found" unless project
     projectid = project['id']
   end
    
   routers = cs_cli.list_routers({projectid: projectid})
   puts
	puts "------ Listing routers which do not belong to a project -------"
	puts "Total number of routers: #{routers.size}"
	routers.each do |router|
	  puts "- #{router["account"]} : #{router["name"]} : #{router["redundantstate"]}"
	end

	puts
	puts "------ Listing routers which belong to a project -------"
	projects = cs_cli.projects
	projects.each do |project|
	  routers = cs_cli.list_routers({:projectid => project['id']})
	  routers.each do |router|
	    puts "- #{router["zonename"]} : #{router["project"]} : #{router["name"]} : #{router["redundantstate"]}"
	  end
	  puts
	end

  end
end