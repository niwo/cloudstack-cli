module CloudstackClient

	module DiskOffering

		##
    # Lists all available disk offerings.

    def list_disk_offerings(domain = nil)
      params = {
          'command' => 'listDiskOfferings'
      }

      if domain
        params['domainid'] = list_domains(domain).first["id"]
      end

      json = send_request(params)
      json['diskoffering'] || []
    end

    ##
    # Get disk offering by name.

    def get_disk_offering(name)

      # TODO: use name parameter
      # listServiceOfferings in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.
      params = {
          'command' => 'listDiskOfferings'
      }
      json = send_request(params)

      services = json['diskoffering']
      return nil unless services

      services.each { |s|
        if s['name'] == name then
          return s
        end
      }
      nil
    end


	end

end