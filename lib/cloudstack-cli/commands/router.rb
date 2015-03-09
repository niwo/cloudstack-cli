class Router < CloudstackCli::Base

  desc "list", "list virtual routers"
  option :project, desc: "name of the project"
  option :account, desc: "name of the account"
  option :zone, desc: "name of the zone"
  option :status, desc: "the status of the router"
  option :redundant_state, desc: "the state of redundant virtual router",
    enum: %w(master backup fault unknown)
  option :listall, type: :boolean, desc: "list all routers"
  option :showid, type: :boolean, desc: "display the router ID"
	option :reverse, type: :boolean, default: false, desc: "reverse listing of routers"
  option :command,
    desc: "command to execute for each router",
    enum: %w(START STOP REBOOT)
	option :concurrency, type: :numeric, default: 10, aliases: '-C',
		desc: "number of concurrent command to execute"
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
      command = options[:command].downcase
      unless %w(start stop reboot).include?(command)
        say "\nCommand #{options[:command]} not supported.", :red
        exit 1
      end
      exit unless yes?("\n#{command.capitalize} the router(s) above? [y/N]:", :magenta)
			routers.each_slice(options[:concurrency]) do | batch |
	      jobs = batch.map do |router|
	        {id: client.send("#{command}_router", router['id'], async: false)['jobid'], name: "#{command.capitalize} router #{router['name']}"}
	      end
	      puts
	      watch_jobs(jobs)
			end
    end
  end

  desc "stop NAME [NAME2 ..]", "stop virtual router(s)"
  option :force, desc: "stop without asking", type: :boolean, aliases: '-f'
  def stop(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nStop router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.stop_router(router['id'], async: false)['jobid'], name: "Stop router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "start NAME [NAME2 ..]", "start virtual router(s)"
  option :force, desc: "start without asking", type: :boolean, aliases: '-f'
  def start(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nStart router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.start_router(router['id'], async: false)['jobid'], name: "Start router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "reboot NAME [NAME2 ..]", "reboot virtual router(s)"
  option :force, desc: "start without asking", type: :boolean, aliases: '-f'
  def reboot(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nReboot router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.reboot_router(router['id'], async: false)['jobid'], name: "Reboot router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "restart NAME [NAME2 ..]", "restart virtual router(s) (stop and start)"
  option :force, desc: "restart without asking", type: :boolean, aliases: '-f'
  def restart(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nRestart router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.stop_router(router['id'], async: false)['jobid'], name: "Stop router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)

    jobs = routers.map do |router|
      {id: client.start_router(router['id'], async: false)['jobid'], name: "Start router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)

    say "Finished.", :green
  end

  desc "destroy NAME [NAME2 ..]", "destroy virtual router(s)"
  option :force, desc: "destroy without asking", type: :boolean, aliases: '-f'
  def destroy(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nDestroy router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.destroy_router(router['id'], async: false)['jobid'], name: "Destroy router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  no_commands do

    def get_router(name)
      unless router = client.get_router(name)
        unless router = client.get_router(name, -1)
         say "Can't find router with name #{name}.", :red
         exit 1
        end
      end
      router
    end

    def print_routers(routers, options = {})
      if routers.size < 1
        say "No routers found."
      else
        table = [[
          'Name', 'Zone', 'Account', 'Project', 'Redundant-State', 'IP', 'Linklocal IP', 'Status', 'Redundant', 'ID'
        ]]
        table[0].delete('ID') unless options[:showid]
        routers.each do |router|
          table << [
            router["name"],
            router["zonename"],
            router["account"],
            router["project"],
            router["redundantstate"],
            router["nic"] && router["nic"].first ? router["nic"].first['ipaddress'] : "",
            router["linklocalip"],
            router["state"],
            router["isredundantrouter"],
            router["id"]
          ]
          table[-1].delete_at(-1) unless table[0].index "ID"
        end
        print_table table
        puts
        say "Total number of routers: #{routers.size}"
      end
    end
  end

end
