class Router < CloudstackCli::Base

	desc "list", "list virtual routers"
  option :project
  option :account
  option :zone
  option :status, desc: "Running or Stopped"
  option :redundant_state, desc: "master, backup, failed or unknown"
  option :listall, type: :boolean
  option :showid, type: :boolean
  option :command, desc: "command to execute for each router: START or STOP"
  option :reverse, type: :boolean, default: false, desc: "reverse listing of routers"
  def list
		cs_cli = CloudstackCli::Helper.new(options[:config])
   	if options[:project]
    	project = client.list_projects.select { |p| p['name'] == options[:project] }.first
     	unless project
     		say "Error: Project '#{options[:project]}' not found", :red
     		exit 1
     	end
     	projectid = project['id']
   	end

		routers = client.list_routers(
			{
				account: options[:account], 
				projectid: projectid,
				status: options[:status],
				zone: options[:zone]
			}
		)
		if options[:listall]
			projects = client.list_projects
			projects.each do |project|
		  	routers = routers + client.list_routers(
		  		{
		  			account: options[:account],
		  			projectid: project['id'],
		  			status: options[:status],
		  			zone: options[:zone]
		  		}
		  	)
		  end
		end

		if options[:redundant_state]
			routers = cs_cli.filter_by(routers, 'redundantstate', options[:redundant_state].downcase)
		end

		routers.reverse! if options[:reverse]
		if routers.size < 1
			say "No routers found."
		else
		  table = [[
		  	'Name', 'Zone', 'Account', 'Project', 'Redundant-State', 'Linklocal IP', 'Status', 'ID'
		  ]]
		  table[0].delete('ID') unless options[:showid]
      routers.each do |router|
        table << [
          router["name"],
          router["zonename"],
          router["account"],
          router["project"],
          router["redundantstate"],
          router["linklocalip"],
          router["state"],
          router["id"]
        ]
        table[-1].delete_at(-1) unless table[0].index "ID"
      end
      print_table table
      puts
      say "Number of routers: #{routers.size}"
	  end

	  if options[:command]
	  	case options[:command].downcase
	  	when "start"
	  		exit unless yes?("Start the routers above? [y/N]:", :magenta)
	  		routers.each do |router|
	  			say "Start router #{router['name']}... "
	  			say "job started ", :green if job = client.start_router(router['id'])
	  			say "(jobid: #{job['jobid']})"
	  		end
	  	when "stop"
	  		exit unless yes?("Stop the routers above? [y/N]:", :magenta)
	  		routers.each do |router|
	  			say "Stop router #{router['name']}... "
	  			say "job started ", :green if job = client.stop_router(router['id'])
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
  	client.stop_router id
  end

  desc "start ID", "start virtual router"
  def start(id)
  	exit unless yes?("Start the router with ID #{id}?", :magenta)
  	client.start_router id
  end

  desc "destroy ID", "destroy virtual router"
  def destroy(id)
  	exit unless yes?("Destroy the router with ID #{id}?", :magenta)
  	say "OK", :green if client.destroy_router(id)
  end

end