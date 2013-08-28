module CloudstackClient

	module PortForwardingRule

		##
    # Lists all port forwarding rules.

    def list_port_forwarding_rules(ip_address_id=nil, project_id)
      params = {
          'command' => 'listPortForwardingRules',
          'listall' => true,
          'isrecursive' => true
      }
      params['ipAddressId'] = ip_address_id if ip_address_id
      params['projectid'] = project_id if project_id
      json = send_request(params)
      json['portforwardingrule'] || []
    end

    ##
    # Gets the SSH port forwarding rule for the specified server.

    def get_ssh_port_forwarding_rule(server, cached_rules=nil)
      rules = cached_rules || list_port_forwarding_rules || []
      rules.find_all { |r|
        r['virtualmachineid'] == server['id'] &&
            r['privateport'] == '22'&&
            r['publicport'] == '22'
      }.first
    end

    ##
    # Creates a port forwarding rule.

    def create_port_forwarding_rule(ip_address_id, private_port, protocol, public_port, virtual_machine_id, async = true)
      params = {
          'command' => 'createPortForwardingRule',
          'ipAddressId' => ip_address_id,
          'privatePort' => private_port,
          'protocol' => protocol,
          'publicPort' => public_port,
          'virtualMachineId' => virtual_machine_id
      }
      async ? send_async_request(params)['portforwardingrule'] : send_request(params)
    end

	end

end