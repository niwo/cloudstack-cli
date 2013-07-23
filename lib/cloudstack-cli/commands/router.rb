class Router < Thor
	include Thor::Actions
	include CommandLineReporter

	desc "list", "list virtual routers"
  option :project
  option :account
  option :zone
  option :status, desc: "Running or Stopped"
  option :redundant_state, desc: "MASTER, BACKUP or UNKNOWN"
  option :listall, type: :boolean
  option :text, type: :boolean, desc: "text output (only the instance name)"
  option :command, desc: "command to execute for each router: START or STOP"
  option :reverse, type: :boolean, default: false, desc: "reverse listing of routers"
  def list
		cs_cli = CloudstackCli::Helper.new(options[:config])
   	if options[:project]
    	project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
     	unless project
     		say "Error: Project '#{options[:project]}' not found", :red
     		exit 1
     	end
     	projectid = project['id']
   	end

		routers = cs_cli.list_routers(
			{
				account: options[:account], 
				projectid: projectid,
				status: options[:status],
				zone: options[:zone]
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
		  			status: options[:status],
		  			zone: options[:zone]
		  		},
		  		options[:redundant_state]
		  	)
		  end
		end

		routers.reverse! if options[:reverse]
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
	        column 'Linklocal IP', width: 15
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
	          column router["linklocalip"]
	          column router["state"]
	        end
	      end
	    end
	  end

	  if options[:command]
	  	case options[:command].downcase
	  	when "start"
	  		exit unless yes?("Start the routers above? [y/N]:", :magenta)
	  		routers.each do |router|
	  			say "Start router #{router['name']}... "
	  			say "job started ", :green if job = cs_cli.start_router(router['id'])
	  			say "(jobid: #{job['jobid']})"
	  		end
	  	when "stop"
	  		exit unless yes?("Stop the routers above? [y/N]:", :magenta)
	  		routers.each do |router|
	  			say "Stop router #{router['name']}... "
	  			say "job started ", :green if job = cs_cli.stop_router(router['id'])
	  			say "(jobid: #{job['jobid']})"
	  		end
	  	else
	  		say "Command #{options[:command]} not supported", :red
	  		exit
	  	end
	  end
  end

  desc "stop ID", "stop virtual router"
  def stop(id)
  	exit unless yes?("Stop the router with ID #{id}?", :magenta)
  	cs_cli = CloudstackCli::Helper.new(options[:config])
  	cs_cli.stop_router id
  end

  desc "start ID", "start virtual router"
  def start(id)
  	exit unless yes?("Start the router with ID #{id}?", :magenta)
  	cs_cli = CloudstackCli::Helper.new(options[:config])
  	cs_cli.start_router id
  end

  desc "destroy ID", "destroy virtual router"
  def destroy(id)
  	exit unless yes?("Destroy the router with ID #{id}?", :magenta)
  	cs_cli = CloudstackCli::Helper.new(options[:config])
  	say "OK", :green if cs_cli.destroy_router(id)
  end

end