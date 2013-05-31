require 'command_line_reporter'

module CloudstackCli
  class Cli
    include CommandLineReporter
    def initialize 
	    @cs = CloudstackClient::Connection.new(
	      options[:cloudstack_url],
	      options[:cloudstack_api_key],
	      options[:cloudstack_secret_key]
	    )
    end 

    def server_offerings
      @server_offerings ||= @cs.list_service_offerings
    end
    

    def templates(type = 'featured', project_id)
      @templates ||= @cs.list_templates(type, project_id)
    end

    def projects
      @projects ||= @cs.list_projects
    end

    def zones
      @zones ||= @cs.list_zones
    end

    def networks(project_id = nil)
      @cs.list_networks(project_id)
    end
    
    def virtual_machines(options = {})
      @cs.list_servers(options)
    end
    
    def virtual_machines_table(vms)
      table(border: true) do
        row do
          column 'Name', width: 20
          column 'State'
          column 'Offering', align: 'right'
          column 'Template', align: 'right', width: 30
          column 'IP\'s', width: 14
          column 'Project'
          column 'Account'
        end
        vms.each do |vm|
          row do
            column vm['name']
            column vm['state']
            column vm['serviceofferingname']
            column vm['templatename']
            column vm['nic'].map { |nic| nic['ipaddress']}.join(" ")
            column vm['project']
            column vm['account']
          end
        end
      end
    end

    def bootstrap_server(name, zone, template, offering, networks, pf_rules = [], project = nil)
		puts "Bootstrap a new server...".color(:yellow)
		server = @cs.create_server(
			name,
			offering,
			template,
			zone,
			networks,
			project
		)

		puts
		puts "server #{server["name"]} has been created.".color(:green)
		puts
		puts "Make sure the server is running...".color(:yellow)
		@cs.wait_for_server_state(server["id"], "Running")
		puts "OK!".color(:green)
		puts
		puts "Get the fqdn of the server...".color(:yellow)
		server_fqdn = @cs.get_server_fqdn(server)
		puts "fqdn is #{server_fqdn}".color(:green)

		if pf_rules.size > 0
			puts
			pf_rules.each do |pf_rule|
				ip_addr = @cs.get_public_ip_address(pf_rule.split(":")[0])
				port = pf_rule.split(":")[1]
			  	print "Create port forwarding rule for port #{port} ".color(:yellow)
			  	@cs.create_port_forwarding_rule(ip_addr["id"], port, 'TCP', port, server["id"])
			  	puts
			end
		end

		puts
		puts "Finish!".color(:green)
    end

    def options
  	  @options ||= CloudstackClient::ConnectionHelper.load_configuration()
    end

    def print_options(options, attr = 'name')
  	  options.to_enum.with_index(1).each do |option, i|
  	    puts "#{i}: #{option[attr]}"
  	  end 	
    end

    def interactive
    	ARGV.clear 
    	puts
    	puts %{We are going to deploy a new server and...
    	 - assign a public IP address
    	 - create a firewall rule for SSH and HTTP access
    	 - connect to the server and install the puppet client}.color(:magenta)
    	puts

    	print "Please provide a name for the new server".background(:blue)
    	puts " (spaces or special characters are NOT allowed): "
    	server_name = gets.chomp

    	if projects.size > 0
    	  puts "Select a project".background(:blue)
    	  print_options(projects)
    	  project = gets.chomp.to_i - 1
    	end

    	puts "Select a computing offering:".background(:blue)
    	print_options(server_offerings)
    	service_offering = gets.chomp.to_i - 1

    	puts "Select a template:".background(:blue)
    	print_options(templates)
    	template = gets.chomp.to_i - 1

    	puts "Select a availability zone:".background(:blue)
    	print_options(zones)
    	zone = gets.chomp.to_i - 1
	
    	# FIXME: show only networks in selected zone
    	puts "Select a network:".background(:blue)
    	project_id = projects[project]['id'] rescue nil
    	networks = @cs.list_networks(project_id)
    	print_options(networks)
    	network = gets.chomp.to_i - 1

    	bootstrap_server(
    	  server_name,
    	  zones[zone]["name"],
    	  templates[template]["name"],
    	  server_offerings[service_offering]["name"],
    	  [networks[network]["name"]],
    	  projects[project]["name"]
    	)
    end
  end
end