module Cloudstack
  module Bootstrap
    class Cli
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

      def templates
	@templates ||= @cs.list_templates('featured')
      end

      def projects
	@projects ||= @cs.list_projects
      end

      def zones
	@zomes ||= @cs.list_zones
      end

      def networks(project_id = nil)
	@cs.list_networks(project_id)
      end

      def bootstrap_server(name, zone, template, offering, interfaces, pf_rules = [], project = nil)
	  puts "Bootstrap a new server on CloudStack...".color(:yellow)
	  server = @cs.create_server(
	    name,
	    offering,
	    template,
	    zone,
	    interfaces,
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
	    puts "Associate an IP address on the CloudStack firewall for the server...".color(:yellow)
	    ip_addr = @cs.associate_ip_address(networks[network]["id"])
	    puts
	    puts "IP is #{ip_addr["ipaddress"]}".color(:green)
	    puts

	    pf_rules.each do |port|
	      puts "Create port forwarding rule for port #{port}".color(:yellow)
	      @cs.create_port_forwarding_rule(ip_addr["id"], port, 'TCP', port, server["id"])
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
	puts %{We are going to deploy a new server on CloudStack and...
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
end
