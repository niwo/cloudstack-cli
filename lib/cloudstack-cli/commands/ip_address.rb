class IpAddress < CloudstackCli::Base

  desc "ip_address release ID", "release public IP address"
  def release(id)
    say("OK", :green) if client.disassociate_ip_address(id)
  end

  desc "ip_address assign NETWORK", "assign a public IP address"
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

  desc "ip_address list", "list public IP address"
  option :project
  option :account
  option :listall
  def list
  	table = [["Address", "Account", "Zone"]]
    addresses = client.list_public_ip_addresses(options)
    if addresses.size < 1
      say "No ip addresses found."
    else
      addresses.each do |address|
        table << [address["ipaddress"], address["account"], address["zonename"]]
      end
      print_table table
    end
  end

end