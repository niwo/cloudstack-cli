module CloudstackClient

	module Template
		
		##
    # Finds the template with the specified name.

    def get_template(name)

      # TODO: use name parameter
      # listTemplates in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.
      params = {
          'command' => 'listTemplates',
          'templateFilter' => 'executable'
      }
      json = send_request(params)

      templates = json['template']
      if !templates then
        return nil
      end

      templates.each { |t|
        if t['name'] == name then
          return t
        end
      }

      nil
    end

    ##
    # Lists all templates that match the specified filter.
    #
    # Allowable filter values are:
    #
    # * featured - templates that are featured and are public
    # * self - templates that have been registered/created by the owner
    # * self-executable - templates that have been registered/created by the owner that can be used to deploy a new VM
    # * executable - all templates that can be used to deploy a new VM
    # * community - templates that are public

    def list_templates(args = {})
      filter = args[:filter] || 'featured'
      params = {
          'command' => 'listTemplates',
          'templateFilter' => filter
      }
      params['projectid'] = args[:project_id] if args[:project_id]
      params['zoneid'] = args[:zone_id] if args[:zone_id]
      
      json = send_request(params)
      json['template'] || []
    end

	end

end