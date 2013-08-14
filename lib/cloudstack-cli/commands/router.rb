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
   	projectid = find_project['id'] if options[:project]
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
			routers = filter_by(routers, 'redundantstate', options[:redundant_state].downcase)
		end

		routers.reverse! if options[:reverse]
		if routers.size < 1
			say "No routers found."
		else
		  table = [[
		  	'Name', 'Zone', 'Account', 'Project', 'Redundant-State', 'IP', 'Linklocal IP', 'Status', 'ID'
		  ]]
		  table[0].delete('ID') unless options[:showid]
      routers.each do |router|
        table << [
          router["name"],
          router["zonename"],
          router["account"],
          router["project"],
          router["redundantstate"],
          router["nic"].first ? router["nic"].first['ipaddress'] : "",
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
	  			say "job started ", :green if job = client.start_router(router['id'], async: false)
	  			say "(jobid: #{job['jobid']})"
	  		end
	  	when "stop"
	  		exit unless yes?("Stop the routers above? [y/N]:", :magenta)
	  		routers.each do |router|
	  			say "Stop router #{router['name']}... "
	  			say "job started ", :green if job = client.stop_router(router['id'], async: false)
	  			say "(jobid: #{job['jobid']})"
	  		end
	  	else
	  		say "Command #{options[:command]} not supported", :red
	  		exit
	  	end
	  end
  end

  desc "stop NAME [NAME2 ..]", "stop virtual router(s)"
  option :force, description: "stop without asking", type: :boolean, aliases: '-f'
  def stop(*names)
  	names.each do |name|
  		router = get_router(name)
  		exit unless options[:force] || yes?("Stop router #{router['name']}?", :magenta)
  		client.stop_router router['id']
  		puts
  	end
  end

  desc "start NAME [NAME2 ..]", "start virtual router(s)"
  option :force, description: "start without asking", type: :boolean, aliases: '-f'
  def start(*names)
  	names.each do |name|
  		router = get_router(name)
  		exit unless options[:force] || yes?("Start router #{router['name']}?", :magenta)
  		client.start_router router['id']
  		puts
  	end
  end

  desc "destroy NAME [NAME2 ..]", "destroy virtual router(s)"
  option :force, description: "destroy without asking", type: :boolean, aliases: '-f'
  def destroy(*names)
  	names.each do |name|
  		router = get_router(name)
  		exit unless options[:force] || yes?("Destroy router #{router['name']}?", :magenta)
  		say "OK", :green if client.destroy_router(router['id'])
  		puts
  	end
  end

  no_commands do
  	def get_router(name)
  		unless router = client.get_router(name)
  			say "Can't find router with name #{name}.", :red
  			exit 1
  		end
  		router
  	end
  end

end