module CloudstackClient

	module Volumes

		##
    # Lists all volumes.

    def list_volumes(project_id = nil)
      params = {
          'command' => 'listVolumes',
          'listall' => true,
      }
      params['projectid'] = project_id if project_id
      json = send_request(params)
      json['network'] || []
    end

	end

end