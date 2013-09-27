module CloudstackClient

	module Host

		##
    # Lists hosts.

    def list_hosts(args = {})
      params = {
        'command' => 'listHosts'
      }

      if args[:zone]
        zone = get_zone(args[:zone])
        unless zone
          puts "Error: zone #{args[:project]} not found."
          exit 1
        end
        params['zoneid'] = zone['id']
      end

      json = send_request(params)
      json['host'] || []
    end

	end

end