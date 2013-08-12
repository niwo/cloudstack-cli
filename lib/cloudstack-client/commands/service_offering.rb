module CloudstackClient

	module ServiceOffering
		
		##
    # Finds the service offering with the specified name.

    def get_service_offering(name)

      # TODO: use name parameter
      # listServiceOfferings in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.
      params = {
          'command' => 'listServiceOfferings'
      }
      json = send_request(params)

      services = json['serviceoffering']
      return nil unless services

      services.each { |s|
        if s['name'] == name then
          return s
        end
      }
      nil
    end

    ##
    # Lists all available service offerings.

    def list_service_offerings(domain = nil)
      params = {
          'command' => 'listServiceOfferings'
      }

      if domain
        params['domainid'] = list_domains(domain).first["id"]
      end

      json = send_request(params)
      json['serviceoffering'] || []
    end

    ##
    # Create a service offering.

    def create_offering(args)
      params = {
          'command' => 'createServiceOffering',
          'name' => args[:name],
          'cpunumber' => args[:cpunumber],
          'cpuspeed' => args[:cpuspeed],
          'displaytext' => args[:displaytext],
          'memory' => args[:memory]
      }

      if args['domain']
        params['domainid'] = list_domains(args['domain']).first["id"]
      end

      params['tags'] = args[:tags] if args[:tags]
      params['offerha'] = 'true' if args[:ha]

      json = send_request(params)
      json['serviceoffering'].first
    end

    ##
    # Delete a service offering.

    def delete_offering(id)
      params = {
          'command' => 'deleteServiceOffering',
          'id' => id
      }

      json = send_request(params)
      json['success']
    end

    def update_offering(args)
      params = {
          'command' => 'updateServiceOffering',
          'id' => args['id']
      }
      params['name'] = args['name'] if args['name']
      params['displaytext'] = args['displaytext'] if args['displaytext']
      params['sortkey'] = args['sortkey'] if args['sortkey']

      json = send_request(params)
      json['serviceoffering']
    end

	end

end