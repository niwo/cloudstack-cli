class Router < CloudstackCli::Base

  desc "list", "list virtual routers"
  option :project, desc: "name of the project"
  option :account, desc: "name of the account"
  option :zone, desc: "name of the zone"
  option :state, desc: "the status of the router"
  option :redundant_state, desc: "the state of redundant virtual router",
    enum: %w(master backup fault unknown)
  option :listall, type: :boolean, desc: "list all routers", default: true
  option :reverse, type: :boolean, default: false, desc: "reverse listing of routers"
  option :command,
    desc: "command to execute for each router",
    enum: %w(START STOP REBOOT STOP_START)
  option :concurrency, type: :numeric, default: 10, aliases: '-C',
    desc: "number of concurrent command to execute"
  option :format, default: "table",
    enum: %w(table json yaml)
  option :showid, type: :boolean, desc: "display the router ID"
  option :verbose, aliases: '-V', desc: "display additional fields"
  option :version, desc: "list virtual router elements by version"
  def list
    resolve_project
    resolve_zone
    resolve_account

    routers = client.list_routers(options)
    # show all routers unless project or account is set
    if options[:listall] && !options[:project] && !options[:account]
      client.list_projects(listall: true).each do |project|
        routers = routers + client.list_routers(
          options.merge(projectid: project['id'])
        )
      end
    end
    print_routers(routers, options)
    execute_router_commands(options[:command].downcase, routers) if options[:command]
  end

  desc "list_from_file FILE", "list virtual routers from file"
  option :reverse, type: :boolean, default: false, desc: "reverse listing of routers"
  option :command,
    desc: "command to execute for each router",
    enum: %w(START STOP REBOOT)
  option :concurrency, type: :numeric, default: 10, aliases: '-C',
    desc: "number of concurrent command to execute"
  option :format, default: "table",
    enum: %w(table json yaml)
  def list_from_file(file)
    routers = parse_file(file)["routers"]
    print_routers(routers, options)
    execute_router_commands(options[:command].downcase, routers) if options[:command]
  end

  desc "stop NAME [NAME2 ..]", "stop virtual router(s)"
  option :force, desc: "stop without confirmation", type: :boolean, aliases: '-f'
  def stop(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nStop router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.stop_router({id: router['id']}, {sync: true})['jobid'], name: "Stop router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "start NAME [NAME2 ..]", "start virtual router(s)"
  option :force, desc: "start without confirmation", type: :boolean, aliases: '-f'
  def start(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nStart router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.start_router({id: router['id']}, {sync: true})['jobid'], name: "Start router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "reboot NAME [NAME2 ..]", "reboot virtual router(s)"
  option :force, desc: "reboot without confirmation", type: :boolean, aliases: '-f'
  def reboot(*names)
    routers = names.map {|name| client.list_routers(name: name).first}
    print_routers(routers)
    exit unless options[:force] || yes?("\nReboot router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.reboot_router({id: router['id']}, {sync: true})['jobid'], name: "Reboot router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "stop_start NAME [NAME2 ..]", "stops and starts virtual router(s)"
  option :force, desc: "stop_start without confirmation", type: :boolean, aliases: '-f'
  def stop_start(*names)
    routers = names.map {|name| get_router(name)}
    print_routers(routers)
    exit unless options[:force] || yes?("\nRestart router(s) above? [y/N]:", :magenta)
    jobs = routers.map do |router|
      {id: client.stop_router({id: router['id']}, {sync: true})['jobid'], name: "Stop router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)

    jobs = routers.map do |router|
      {id: client.start_router({id: router['id']}, {sync: true})['jobid'], name: "Start router #{router['name']}"}
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
      {id: client.destroy_router({id: router['id']}, {sync: true})['jobid'], name: "Destroy router #{router['name']}"}
    end
    puts
    watch_jobs(jobs)
  end

  desc "show NAME [NAME2 ..]", "show detailed infos about a virtual router(s)"
  option :project
  def show(*names)
    routers = names.map {|name| get_router(name)}
    table = []
    routers.each do |router|
      router.each do |key, value|
        table << [ set_color("#{key}:", :yellow), "#{value}" ]
      end
      table << [ "-" * 20 ] unless router == routers[-1]
    end
    print_table table
  end

  no_commands do

    def get_router(name)
      unless router = client.list_routers(name: name, listall: true).first
        unless router = client.list_routers(name: name, project_id: -1).first
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
        if options[:redundant_state]
          routers = filter_by(
            routers,
            'redundantstate',
            options[:redundant_state].downcase
          )
        end
        routers.reverse! if options[:reverse]

        options[:format] ||= "table"
        case options[:format].to_sym
        when :yaml
          puts({'routers' => routers}.to_yaml)
        when :json
          say JSON.pretty_generate(routers: routers)
        else
          table = [%w(
            Name Zone Account/Project IP Linklocal-IP Status Version
          )]
          table[0].unshift('ID') if options[:showid]
          if options[:verbose]
            table[0].push('Redundant-State', 'Requ-Upgrade', 'Offering')
          end
          routers.each do |router|
            table << [
              router["name"],
              router["zonename"],
              router["project"] || router["account"],
              router["nic"] && router["nic"].first ? router["nic"].first['ipaddress'] : "-",
              router["linklocalip"] || "-",
              router["state"],
              router["version"] || "-"
            ]
            table[-1].unshift(router["id"]) if options[:showid]
            if options[:verbose]
              table[-1].push(
                print_redundant_state(router),
                router["requiresupgrade"] || "-",
                router["serviceofferingname"]
              )
            end
          end
          print_table table
          puts
          say "Total number of routers: #{routers.size}"
        end
      end
    end

    def print_redundant_state(router)
      router["isredundantrouter"] == "true" ? router["redundantstate"] : "non-redundant"
    end

    def execute_router_commands(command, routers)
      unless %w(start stop reboot stop_start).include?(command)
        say "\nCommand #{options[:command]} not supported.", :red
        exit 1
      end
      exit unless yes?("\n#{command.capitalize} the router(s) above? [y/N]:", :magenta)

      command.split("_").each do |cmd|
        jobs = routers.map do |router|
          {
            job_id: nil,
            object_id: router["id"],
            name: "#{cmd.capitalize} router #{router['name']}",
            status: -1
          }
        end
        run_background_jobs(jobs, "#{cmd}_router")
      end
    end

  end

end
