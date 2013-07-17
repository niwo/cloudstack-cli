class Router < Thor
	include CommandLineReporter

	desc "list", "list virtual routers"
  option :project
  option :account
  option :status, desc: "Running or Stopped"
  option :redundant_state, desc: "MASTER, BACKUP or UNKNOWN"
  option :listall, type: :boolean
  option :text, type: :boolean, desc: "text output (only the instance name)"
  def list
		cs_cli = CloudstackCli::Helper.new
   	if options[:project]
    	project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
     	raise "Project '#{options[:project]}' not found" unless project
     	projectid = project['id']
   	end

		routers = cs_cli.list_routers(
			{
				account: options[:account], 
				projectid: projectid,
				status: options[:status],
			}, 
			options[:redundant_state]
		)


		if options[:listall]
			projects = cs_cli.projects
			projects.each do |project|
		  	routers = routers + cs_cli.list_routers(
		  		{
		  			account: options[:account],
		  			projectid: project['id'],
		  			status: options[:status]
		  		},
		  		options[:redundant_state]
		  	)
		  end
		end

		if options[:text]
			puts routers.map {|r| r['name']}.join(" ")
		else
		  puts "Total number of routers: #{routers.size}"
			table(border: true) do
	    	row do
	    		column 'ID', width: 40
	        column 'Name'
	        column 'Zone'
	        column 'Account', width: 14 unless options[:project]
	        column 'Project', width: 14 if options[:listall] || options[:project]
	        column 'Redundant State'
	        column 'Public IP', width: 15
	        column 'Status'
	      end
	      routers.each do |router|
	        row do
	        	column router["id"]
	          column router["name"]
	          column router["zonename"]
	          column router["account"] unless options[:project]
	          column router["project"] if options[:listall] || options[:project]
	          column router["redundantstate"]
	          column router["publicip"]
	          column router["state"]
	        end
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

  desc "destroy ID", "destroy virtual router"
  def destroy(id)
  	cs_cli = CloudstackCli::Helper.new
  	puts "OK" if cs_cli.destroy_router(name)
  end

end