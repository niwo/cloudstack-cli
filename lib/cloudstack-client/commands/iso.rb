module CloudstackClient

	module Iso

		##
    # Lists all isos that match the specified filter.
    #
    # Allowable filter values are:
    #
    # * featured - isos that are featured and are public
    # * self - isos that have been registered/created by the owner
    # * self-executable - isos that have been registered/created by the owner that can be used to deploy a new VM
    # * executable - all isos that can be used to deploy a new VM
    # * community - isos that are public

    def list_isos(args = {})
      filter = args[:filter] || 'featured'
      params = {
          'command' => 'listIsos',
          'isoFilter' => filter
      }
      params['projectid'] = args[:project_id] if args[:project_id]
      params['zoneid'] = args[:zone_id] if args[:zone_id]
      if args[:listall]
        params['listall'] = true
        params['isrecursive'] = true
      end
      
      json = send_request(params)
      json['iso'] || []
    end

    ##
    # Finds the template with the specified name.

    def get_iso(name)

      # TODO: use name parameter
      # listIsos in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.
      params = {
          'command' => 'listIsos',
          'isoFilter' => 'executable'
      }
      json = send_request(params)

      isos = json['iso']
      if !isos then
        return nil
      end

      isos.each { |t|
        if t['name'] == name then
          return t
        end
      }

      nil
    end

	end

end