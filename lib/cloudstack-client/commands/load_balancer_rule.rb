module CloudstackClient

	module LoadBalancerRule

		##
    # List loadbalancer rules

    def list_load_balancer_rules(options = {})    
      params = {
        'command' => 'listLoadBalancerRules',
      }
      params['name'] = options[:name] if options[:name]

      if options[:project_name]
        project = get_project(options[:project_name])
        params['projectid'] = project['id']
      end

      json = send_request(params)
      json['loadbalancerrule'] || []
    end

    ##
    # Creates a load balancing rule.

    def create_load_balancer_rule(name, publicip, private_port, public_port, options = {})
      params = {
          'command' => 'createLoadBalancerRule',
          'name' => name,
          'privateport' => private_port,
          'publicport' => public_port,
          'publicipid' => get_public_ip_address(publicip)['id']
      }
      params['algorithm'] = options[:algorithm] || 'roundrobin'
      params['openfirewall'] = options[:openfirewall] || true

      json = send_async_request(params)
      json['LoadBalancerRule']
    end

    ##
    # Assigns virtual machine or a list of virtual machines to a load balancer rule.

    def assign_to_load_balancer_rule(name, vm_names)
      id = list_load_balancer_rules(name).first['id']

      vm_ids = vm_names.map do |vm|
        get_server(vm)['id']
      end

      params = {
          'command' => 'assignToLoadBalancerRule',
          'id' => id,
          'virtualmachineids' => vm_ids.join(',')
      }
      json = send_async_request(params)
    end

	end

end