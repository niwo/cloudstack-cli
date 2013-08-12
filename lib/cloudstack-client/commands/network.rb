module CloudstackClient

	module Network

		##
    # Finds the network with the specified name.

    def get_network(name, project_id = nil)
      params = {
          'command' => 'listNetworks',
          'listall' => true
      }
      params['projectid'] = project_id if project_id
      json = send_request(params)

      networks = json['network']
      return nil unless networks

      networks.each { |n|
        if n['name'] == name then
          return n
        end
      }
      nil
    end

    ##
    # Finds the default network.

    def get_default_network(zone = nil)
      params = {
          'command' => 'listNetworks',
          'isDefault' => true
      }
      if zone
        params['zoneid'] = get_zone(zone)['id']
      end
      json = send_request(params)

      networks = json['network']
      return nil if !networks || networks.empty?
      return networks.first if networks.length == 1

      networks.each { |n|
        if n['type'] == 'Direct' then
          return n
        end
      }
      nil
    end

    ##
    # Lists all available networks.

    def list_networks(args = {})
      params = {
        'command' => 'listNetworks',
        'listall' => true,
      }
      params['projectid'] = args[:project_id] if args[:project_id]
      params['zoneid'] = args[:zone_id] if args[:zone_id]
      params['isDefault'] = true if args[:isdefault]
      if args[:account]
        domain = list_accounts(name: args[:account])
        if domain.size > 0
          params['account'] = args[:account]
          params['domainid'] = domain.first["domainid"]
        else
          puts "Account #{args[:account]} not found."
        end
      end
      json = send_request(params)
      json['network'] || []
    end

    ##
    # Delete network.

    def delete_network(id)
      params = {
        'command' => 'deleteNetwork',
        'id' => id,
      }
      p json = send_async_request(params)
      json['network']
    end

    ##
    # Lists all physical networks.

    def list_physical_networks
      params = {
          'command' => 'listPhysicalNetworks',
      }
      json = send_request(params)
      json['physicalnetwork'] || []
    end

	end

end