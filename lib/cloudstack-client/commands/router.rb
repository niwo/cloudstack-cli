module CloudstackClient

	module Router

    ##
    # Get a router with a given name.

    def get_router(name)
      params = {
          'command' => 'listRouters',
          'listall' => 'true',
          'name' => name
      }

      json = send_request(params)
      json['router'] ? json['router'].first : nil
    end

		##
    # Lists all virtual routers.

    def list_routers(args = {:account => nil, :zone => nil, :projectid => nil, :status => nil, :name => nil})
      params = {
          'command' => 'listRouters',
          'listall' => 'true',
          'isrecursive' => 'true'
      }
      if args[:zone]
        zone = get_zone(args[:zone])
        unless zone 
          puts "Error: Zone #{args[:zone]} not found"
          exit 1
        end
        params['zoneid'] = zone['id']  
      end
      params['projectid'] = args[:projectid] if args[:projectid]
      params['state'] = args[:status] if args[:status]
      params['name'] = args[:name] if args[:name]
      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end

      json = send_request(params)
      json['router'] || []
    end

    ##
    # Destroy virtual router.

    def destroy_router(id, opts = {async: true})
      params = {
        'command' => 'destroyRouter',
        'id' => id
      }
      opts[:async] ? send_async_request(params)['router'] : send_request(params)
    end

    ##
    # Start virtual router.

    def start_router(id, opts = {async: true})
      params = {
        'command' => 'startRouter',
        'id' => id
      }
      opts[:async] ? send_async_request(params)['router'] : send_request(params)
    end

    ##
    # Stop virtual router.

    def stop_router(id, opts = {async: true})
      params = {
        'command' => 'stopRouter',
        'id' => id
      }
      opts[:async] ? send_async_request(params)['router'] : send_request(params)
    end

	end

end