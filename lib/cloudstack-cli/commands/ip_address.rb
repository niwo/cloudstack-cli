class IpAddress < CloudstackCli::Base

  desc "release ID", "release public IP address"
  def release(id)
    puts "OK" if client.disassociate_ip_address(id)
  end

  desc "assign NETWORK", "assign a public IP address"
  option :project
  def assign(network)
  	project = find_project if options[:project]
  	unless network = client.get_network(network, project ? project["id"] : nil)
  		error "Network #{network} not found."
  		exit 1
  	end
  	ip = client.associate_ip_address(network["id"])
  	puts
  	say ip['ipaddress']
  end

  desc "list", "list public IP address"
  option :project
  option :account
  option :listall
  def list
  	table = [["Address", "Account", "Zone"]]
  	client.list_public_ip_addresses(options).each do |address|
  		table << [address["ipaddress"], address["account"], address["zonename"]]
  	end
  	print_table table
  end

end