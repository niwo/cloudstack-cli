module CloudstackClient

	module Domain
		
		##
    # List domains.

    def list_domains(name = nil)
      params = {
        'command' => 'listDomains',
        'listall' => 'true',
        'isrecursive' => 'true'
      }
      params['name'] = name if name

      json = send_request(params)
      json['domain'] || []
    end

  end

end