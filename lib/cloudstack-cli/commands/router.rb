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
    
    print_routers(routers, options)		

	  if options[:command]
	  	case options[:command].downcase
	  	when "start"
	  		exit unless yes?("\nStart the router(s) above? [y/N]:", :magenta)
	  		jobs = routers.map do |router|
	  			{id: client.start_router(router['id'], async: false)['jobid'], name: "Start router #{router['name']}"}
	  		end
	  	when "stop"
	  		exit unless yes?("\nStop the router(s) above? [y/N]:", :magenta)
	  		jobs = routers.map do |router|
	  			{id: client.stop_router(router['id'], async: false)['jobid'], name: "Stop router #{router['name']}"}
	  		end
	  	else
	  		say "\nCommand #{options[:command]} not supported.", :red
	  		exit 1
	  	end
      puts
      watch_jobs(jobs)
	  end
  end

  desc "stop NAME [NAME2 ..]", "stop virtual router(s)"
  option :force, description: "stop without asking", type: :boolean, aliases: '-f'
  def stop(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nStop router(s) above?", :magenta)
  	jobs = routers.map do |router|
  		{id: client.stop_router(router['id'], async: false)['jobid'], name: "Stop router #{router['name']}"}
  	end
    puts
    watch_jobs(jobs)
  end

  desc "start NAME [NAME2 ..]", "start virtual router(s)"
  option :force, description: "start without asking", type: :boolean, aliases: '-f'
  def start(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nStart router(s) above?", :magenta)
  	jobs = routers.map do |router|
      {id: client.start_router(router['id'], async: false)['jobid'], name: "Start router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "destroy NAME [NAME2 ..]", "destroy virtual router(s)"
  option :force, description: "destroy without asking", type: :boolean, aliases: '-f'
  def destroy(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nDestroy router(s) above?", :magenta)
  	jobs = routers.map do |router|
  		{id: client.destroy_router(router['id'], async: false)['jobid'], name: "Destroy router #{router['name']}"}
  	end
    puts
    watch_jobs(jobs)
  end

  no_commands do

  	def get_router(name)
  		unless router = client.get_router(name)
  			say "Can't find router with name #{name}.", :red
  			exit 1
  		end
  		router
  	end

    def print_routers(routers, options = {})
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
    end
  end

end