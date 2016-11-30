class IpAddress < CloudstackCli::Base

  desc "release ID [ID2 ID3]", "release public IP address by ID"
  def release(*ids)
    ids.each do |id|
      say(" OK, released address with ID #{id}", :green) if client.disassociate_ip_address(id: id)
    end
  end

  desc "assign NETWORK", "assign a public IP address"
  option :project
  def assign(network)
    resolve_project
    options[:name] = network
    unless network = client.list_networks(options).first
      error "Network #{network} not found."
      exit 1
    end

    if address = client.associate_ip_address(networkid: network["id"])
      say " OK. Assigned IP address:", :green
      table = [%w(ID Address Account Zone)]
      table << [address["id"], address["ipaddress"], address["account"], address["zonename"]]
      print_table table
    end
  end

  desc "list", "list public IP address"
  option :project
  option :account
  option :listall, type: :boolean, default: true
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_account
    resolve_project
    addresses = client.list_public_ip_addresses(options)
    if addresses.size < 1
      say "No ip addresses found."
    else
      case options[:format].to_sym
      when :yaml
        puts({ip_addresses: addresses}.to_yaml)
      when :json
        puts JSON.pretty_generate(ip_addresses: addresses)
      else
        table = [%w(ID Address Account Zone)]
        addresses.each do |address|
          table << [address["id"], address["ipaddress"], address["account"], address["zonename"]]
        end
        print_table table
        say "Total number of addresses: #{addresses.size}"
      end
    end
  end

end
