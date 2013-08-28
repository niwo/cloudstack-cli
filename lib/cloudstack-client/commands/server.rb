module CloudstackClient

	module Server

		##
    # Finds the server with the specified name.

    def get_server(name, project_id=nil)
      params = {
          'command' => 'listVirtualMachines',
          'name' => name
      }
      params['projectid'] = project_id if project_id
      json = send_request(params)
      machines = json['virtualmachine']

      if !machines || machines.empty? then
        return nil
      end

      machines.select {|m| m['name'] == name }.first
    end

    def get_server_state(id)
      params = {
          'command' => 'listVirtualMachines',
          'id' => id
      }
      json = send_request(params)
      machine_state = json['virtualmachine'][0]['state']

      if !machine_state || machine_state.empty?
        return nil
      end

      machine_state
    end

    def wait_for_server_state(id, state)
      while get_server_state(id) != state
        print '..'
        sleep 5 
      end
      state
    end

    ##
    # Finds the public ip for a server

    def get_server_public_ip(server, cached_rules=nil)
      return nil unless server

      # find the public ip
      nic = get_server_default_nic(server) || {}
      if nic['type'] == 'Virtual'
        ssh_rule = get_ssh_port_forwarding_rule(server, cached_rules)
        ssh_rule ? ssh_rule['ipaddress'] : nil
      else
        nic['ipaddress']
      end
    end

    ##
    # Returns the fully qualified domain name for a server.

    def get_server_fqdn(server)
      return nil unless server

      nic = get_server_default_nic(server) || {}
      networks = list_networks(project_id: server['projectid']) || {}

      id = nic['networkid']
      network = networks.select { |net|
        net['id'] == id
      }.first
      return nil unless network

      "#{server['name']}.#{network['networkdomain']}"
    end

    def get_server_default_nic(server)
      server['nic'].each do |nic|
        return nic if nic['isdefault']
      end
    end

    ##
    # Lists all the servers in your account.

    def list_servers(options = {})
      params = {
        'command' => 'listVirtualMachines',
        'listAll' => true
      }
      params['projectid'] = options[:project_id] if options[:project_id]
      if options[:account]
        if account = list_accounts({name: options[:account]}).first
          params['domainid'] = account["domainid"]
          params['account'] = options[:account]
        end
      end

      json = send_request(params)
      json['virtualmachine'] || []
    end

    ##
    # Deploys a new server using the specified parameters.

    def create_server(args = {})
      if args[:name]
        if get_server(args[:name])
          puts "Error: Server '#{args[:name]}' already exists."
          exit 1
        end
      end

      service = get_service_offering(args[:offering])
      if !service
        puts "Error: Service offering '#{args[:offering]}' is invalid"
        exit 1
      end

      if args[:template]
        template = get_template(args[:template])
        if !template
          puts "Error: Template '#{args[:template]}' is invalid"
          exit 1
        end
      end

      if args[:disk_offering]
        disk_offering = get_disk_offering(args[:disk_offering])
        unless disk_offering
          msg = "Disk offering '#{args[:disk_offering]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
      end

      if args[:iso]
        iso = get_iso(args[:iso])
        unless iso
          puts "Error: Iso '#{args[:iso]}' is invalid"
          exit 1
        end
        unless disk_offering
          puts "Error: a disk offering is required when using iso"
          exit 1
        end
      end

      if !template && !iso
        puts "Error: Iso or Template is required"
        exit 1
      end

      zone = args[:zone] ? get_zone(args[:zone]) : get_default_zone
      if !zone
        msg = args[:zone] ? "Zone '#{args[:zone]}' is invalid" : "No default zone found"
        puts "Error: #{msg}"
        exit 1
      end

      if args[:project]
        project = get_project(args[:project])
        if !project
          msg = "Project '#{args[:project]}' is invalid"
          puts "Error: #{msg}"
          exit 1
        end
      end

      networks = []
      if args[:networks]
        args[:networks].each do |name|
          network = project ? get_network(name, project['id']) : get_network(name)
          if !network
            puts "Error: Network '#{name}' not found"
            exit 1
          end
          networks << network
        end
      end
      if networks.empty?
        networks << get_default_network
      end
      if networks.empty?
        puts "No default network found"
        exit 1
      end
      network_ids = networks.map { |network|
        network['id']
      }

      params = {
          'command' => 'deployVirtualMachine',
          'serviceOfferingId' => service['id'],
          'templateId' => template ? template['id'] : iso['id'],
          'zoneId' => zone['id'],
          'networkids' => network_ids.join(',')
      }
      params['name'] = args[:name] if args[:name]
      params['projectid'] = project['id'] if project
      params['diskofferingid'] = disk_offering['id'] if disk_offering
      params['hypervisor'] = (args[:hypervisor] || 'vmware') if iso
      params['keypair'] = args[:keypair] if args[:keypair]
      params['size'] = args[:disk_size] if args[:disk_size]
      params['group'] = args[:group] if args[:group]
      params['displayname'] = args[:displayname] if args[:displayname]

      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end

      args[:sync] ? send_request(params) : send_async_request(params)['virtualmachine']
    end

    ##
    # Stops the server with the specified name.
    #

    def stop_server(name, forced=nil)
      server = get_server(name)
      if !server || !server['id']
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'stopVirtualMachine',
          'id' => server['id']
      }
      params['forced'] = true if forced

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Start the server with the specified name.
    #

    def start_server(name)
      server = get_server(name)
      if !server || !server['id']
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'startVirtualMachine',
          'id' => server['id']
      }

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Reboot the server with the specified name.
    #

    def reboot_server(name)
      server = get_server(name)
      if !server || !server['id']
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'rebootVirtualMachine',
          'id' => server['id']
      }

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Destroy the server with the specified name.
    #

    def destroy_server(id, async = true)
      params = {
          'command' => 'destroyVirtualMachine',
          'id' => id
      }

      async ? send_async_request(params)['virtualmachine'] : send_request(params)
    end
  
  end

 end