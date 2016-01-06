require 'thread'

class VirtualMachine < CloudstackCli::Base

  desc "list", "list virtual machines"
  option :account, desc: "name of the account"
  option :project, desc: "name of the project"
  option :zone, desc: "the name of the availability zone"
  option :state, desc: "state of the virtual machine"
  option :listall, desc: "list all virtual machines", default: true
  option :storage_id, desc: "the storage ID where vm's volumes belong to"
  option :host, desc: "the name of the hypervisor host the VM belong to"
  option :keyword, desc: "filter by keyword"
  option :command,
    desc: "command to execute for the given virtual machines",
    enum: %w(START STOP REBOOT)
  option :concurrency, type: :numeric, default: 10, aliases: '-C',
    desc: "number of concurrent command to execute"
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_account
    resolve_project
    resolve_zone
    resolve_host
    command = options[:command].downcase if options[:command]
    options.delete(:command)
    virtual_machines = client.list_virtual_machines(options)
    if virtual_machines.size < 1
      puts "No virtual_machines found."
    else
      print_virtual_machines(virtual_machines)
      execute_virtual_machines_commands(command, virtual_machines) if command
    end
  end

  desc "list_from_file FILE", "list virtual machines from file"
  option :command,
  desc: "command to execute for the given virtual machines",
  enum: %w(START STOP REBOOT)
  option :concurrency, type: :numeric, default: 10, aliases: '-C',
  desc: "number of concurrent command to execute"
  option :format, default: :table, enum: %w(table json yaml)
  def list_from_file(file)
    virtual_machines = parse_file(file)["virtual_machines"]
    if virtual_machines.size < 1
      puts "No virtual machines found."
    else
      print_virtual_machines(virtual_machines)
      execute_virtual_machines_commands(
        options[:command].downcase,
        virtual_machines
      ) if options[:command]
    end
  end

  desc "show NAME", "show detailed infos about a virtual machine"
  option :project
  def show(name)
    resolve_project
    options[:name] = name
    unless virtual_machine = client.list_virtual_machines({list_all: true}.merge options).first
      puts "No virtual machine found."
    else
      table = virtual_machine.map do |key, value|
        [ set_color("#{key}:", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

  desc "create NAME [NAME2 ...]", "create virtual machine(s)"
  option :template, aliases: '-t', desc: "name of the template"
  option :iso, desc: "name of the iso template"
  option :offering, aliases: '-o', required: true, desc: "computing offering name"
  option :zone, aliases: '-z', required: true, desc: "availability zone name"
  option :networks, aliases: '-n', type: :array, desc: "network names"
  option :project, aliases: '-p', desc: "project name"
  option :port_rules, aliases: '-pr', type: :array,
    default: [],
    desc: "Port Forwarding Rules [public_ip]:port ..."
  option :disk_offering, desc: "disk offering (data disk for template, root disk for iso)"
  option :disk_size, desc: "disk size in GB"
  option :hypervisor, desc: "only used for iso deployments, default: vmware"
  option :keypair, desc: "the name of the ssh keypair to use"
  option :group, desc: "group name"
  option :account, desc: "account name"
  def create(*names)
    vm_options_to_params

    say "Start deploying virtual machine#{ "s" if names.size > 1 }...", :green
    jobs = names.map do |name|
      if virtual_machine = client.list_virtual_machines(name: name, project_id: options[:project_id]).first
        say "virtual machine #{name} (#{virtual_machine["state"]}) already exists.", :yellow
        job = {
          id: 0,
          name: "Create virtual machine #{name}",
          status: 1
        }
      else
        job = {
          id: client.deploy_virtual_machine(options, {sync: true})['jobid'],
          name: "Create virtual machine #{name}"
        }
      end
      job
    end
    watch_jobs(jobs)
    if options[:port_rules].size > 0
      say "Create port forwarding rules...", :green
      jobs = []
      names.each do |name|
        virtual_machine = client.list_virtual_machine(name: name, project_id: options[:project_id]).first
        create_port_rules(virtual_machine, options[:port_rules], false).each_with_index do |job_id, index|
          jobs << {
            id: job_id,
            name: "Create port forwarding ##{index + 1} rules for virtual machine #{virtual_machine['name']}"
          }
        end
      end
      watch_jobs(jobs)
    end
    say "Finished.", :green
  end

  desc "destroy NAME [NAME2 ..]", "destroy virtual machine(s)"
  option :project
  option :force, desc: "destroy without asking", type: :boolean, aliases: '-f'
  option :expunge, desc: "expunge virtual machine immediately", type: :boolean, default: false, aliases: '-E'
  def destroy(*names)
    resolve_project
    names.each do |name|
      unless virtual_machine = client.list_virtual_machines(options.merge(name: name, listall: true)).first
        say "Virtual machine #{name} not found.", :red
      else
        ask = "Destroy #{name} (#{virtual machine['state']})? [y/N]:"
        if options[:force] || yes?(ask, :yellow)
          say "destroying #{name} "
          client.destroy_virtual_machine(
            id: virtual_machine["id"],
            expunge: options[:expunge]
          )
          puts
        end
      end
    end
  end

  desc "create_interactive", "interactive creation of a virtual machine with network access"
  def create_interactive
    bootstrap_server_interactive
  end

  desc "stop NAME", "stop a virtual machine"
  option :project
  option :force
  def stop(name)
    resolve_project
    options[:name] = name
    options[:listall] = true
    exit unless options[:force] || yes?("Stop virtual machine #{name}? [y/N]:", :magenta)
    unless virtual_machine = client.list_virtual_machines(options).first
      say "Virtual machine #{name} not found.", :red
      exit 1
    end
    client.stop_virtual_machine(id: virtual_machine['id'])
    puts
  end

  desc "start NAME", "start a virtual_machine"
  option :project
  def start(name)
    resolve_project
    options[:name] = name
    options[:listall] = true
    unless virtual_machine = client.list_virtual_machines(options).first
      say "Virtual machine #{name} not found.", :red
      exit 1
    end
    say("Starting virtual machine #{name}", :magenta)
    client.start_virtual_machine(id: virtual_machine['id'])
    puts
  end

  desc "reboot NAME", "reboot a virtual machine"
  option :project
  option :force
  def reboot(name)
    resolve_project
    options[:name] = name
    options[:listall] = true
    unless virtual_machine = client.list_virtual_machines(options).first
      say "Virtual machine #{name} not found.", :red
      exit 1
    end
    exit unless options[:force] || yes?("Reboot virtual_machine #{name}? [y/N]:", :magenta)
    client.reboot_virtual_machine(id: virtual_machine['id'])
    puts
  end

  no_commands do

    def print_virtual_machines(virtual_machines)
      case options[:format].to_sym
      when :yaml
        puts({'virtual_machines' => virtual_machines}.to_yaml)
      when :json
        say MultiJson.dump({ virtual_machines: virtual_machines }, pretty: true)
      else
        with_i_name = virtual_machines.first['instancename']
        with_h_name = virtual_machines.first['hostname']
        table = [["Name", "State", "Offering", "Zone", options[:project_id] ? "Project" : "Account", "IP's"]]
        table.first.insert(1, "Instance-Name") if with_i_name
        table.first.insert(-1, "Host-Name") if with_h_name
        virtual_machines.each do |virtual_machine|
          table << [
            virtual_machine['name'],
            virtual_machine['state'],
            virtual_machine['serviceofferingname'],
            virtual_machine['zonename'],
            options[:project_id] ? virtual_machine['project'] : virtual_machine['account'],
            virtual_machine['nic'].map { |nic| nic['ipaddress']}.join(' ')
          ]
          table.last.insert(1, virtual_machine['instancename']) if with_i_name
          table.last.insert(-1, virtual_machine['hostname']) if with_h_name
        end
        print_table table
        say "Total number of virtual machines: #{virtual_machines.count}"
      end
    end

    def execute_virtual_machines_commands(command, virtual_machines)
      unless %w(start stop reboot).include?(command)
        say "\nCommand #{options[:command]} not supported.", :red
        exit 1
      end
      exit unless yes?("\n#{command.capitalize} the virtual_machine(s) above? [y/N]:", :magenta)

      jobs = virtual_machines.map do |vm|
        {
          job_id: nil,
          object_id: vm["id"],
          name: "#{command.capitalize} virtual machine #{vm['name']}",
          status: -1
        }
      end

      run_background_jobs(jobs, "#{command}_virtual_machine")
    end

  end # no_commands

end
