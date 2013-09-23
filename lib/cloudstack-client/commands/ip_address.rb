module CloudstackClient

	module IpAddress

		##
    # Lists the public ip addresses.

    def list_public_ip_addresses(args = {})
      params = {
          'command' => 'listPublicIpAddresses',
          'isrecursive' => true
      }
      if args[:project]
        project = get_project(args[:project])
        unless project
          puts "Error: project #{args[:project]} not found."
          exit 1
        end
        params['projectid'] = project['id']
      end
      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end
      params['listall'] = args[:listall] if args[:listall]

      json = send_request(params)
      json['publicipaddress'] || []
    end

    ##
    # Finds the public ip address for a given ip address string.

    def get_public_ip_address(ip_address, project_id = nil)
      params = {
          'command' => 'listPublicIpAddresses',
          'ipaddress' => ip_address
      }
      params['projectid'] = project_id if project_id
      json = send_request(params)
      ip_address = json['publicipaddress']

      return nil unless ip_address
      ip_address.first
    end


    ##
    # Acquires and associates a public IP to an account.

    def associate_ip_address(network_id)
      params = {
          'command' => 'associateIpAddress',
          'networkid' => network_id
      }

      json = send_async_request(params)
      json['ipaddress']
    end

    ##
    # Disassociates an ip address from the account.
    #
    # Returns true if successful, false otherwise.

    def disassociate_ip_address(id)
      params = {
          'command' => 'disassociateIpAddress',
          'id' => id
      }
      json = send_async_request(params)
      json['success']
    end

	end

end