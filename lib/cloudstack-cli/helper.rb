module CloudstackCli
  class Helper
    attr_reader :cs

    def initialize(config_file)
      @config_file = config_file
	    @cs = CloudstackClient::Connection.new(
	      options[:url],
	      options[:api_key],
	      options[:secret_key]
	    )
    end

    def options
       @options ||= CloudstackClient::ConnectionHelper.load_configuration(@config_file)
    end

    def print_options(options, attr = 'name')
      options.to_enum.with_index(1).each do |option, i|
         puts "#{i}: #{option[attr]}"
      end   
    end

    def domains(name = nil)
      @cs.list_domains(name)
    end

    def server_offerings(domain = nil)
      @server_offerings ||= @cs.list_service_offerings(domain)
    end
    
    def templates(type = 'featured', project_id = -1)
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


    def volumes(project_id = nil)
      @cs.list_volumes(project_id)
    end
    
    def virtual_machines(options = {})
      @cs.list_servers(options)
    end

    def bootstrap_server(name, zone, template, offering, networks, pf_rules = [], project = nil)
  		puts "Create server #{name}...".color(:yellow)
  		server = @cs.create_server(
  			name,
  			offering,
  			template,
  			zone,
  			networks,
  			project
  		)

  		puts
  		puts "Server #{server["name"]} has been created.".color(:green)
  		puts
  		puts "Make sure the server is running...".color(:yellow)
  		@cs.wait_for_server_state(server["id"], "Running")
  		puts "OK!".color(:green)
  		puts
  		puts "Get the fqdn of the server...".color(:yellow)
  		server_fqdn = @cs.get_server_fqdn(server)
  		puts "FQDN is #{server_fqdn}".color(:green)

  		if pf_rules.size > 0
  			puts
  			pf_rules.each do |pf_rule|
          ip = pf_rule.split(":")[0]
  				ip_addr = @cs.get_public_ip_address(ip)
  				port = pf_rule.split(":")[1]
  			  	print "Create port forwarding rule #{ip}:#{port} ".color(:yellow)
  			  	@cs.create_port_forwarding_rule(ip_addr["id"], port, 'TCP', port, server["id"])
  			  	puts
  			end
  		end

  		puts
  		puts "Complete!".color(:green)
    end

    def list_accounts(name = nil)
      @cs.list_accounts({ name: name })
    end 

    def list_load_balancer_rules(project = nil)
      @cs.list_load_balancer_rules(project)
    end

    def create_load_balancer_rule(name, ip, private_port, public_port, options = {})
      puts "Create rule #{name}...".color(:yellow)
      @cs.create_load_balancer_rule(name, ip, private_port, public_port, options = {})
      puts "OK!".color(:green)
    end

    def assign_to_load_balancer_rule(id, names)
      puts "Add #{names.join(', ')} to rule #{id}...".color(:yellow)
      rule = @cs.assign_to_load_balancer_rule(id, names)
      if rule['success']
        puts "OK!".color(:green)
      else
        puts "Failed!".color(:red)
      end
    end

    def filter_by(objects, tag_name, tag)
      objects.select {|r| r[tag_name].downcase == tag }
    end

    def bootstrap_server_interactive
      ARGV.clear 
    	puts
    	puts "We are going to deploy a new server and..."
    	puts "- assign a public IP address"
    	puts "- create a firewall rule for SSH and HTTP access"
    	puts "- connect to the server and install the puppet client}"
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