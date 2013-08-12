module CloudstackClient

	module Project

		##
    # Get project by name.

    def get_project(name)
      params = {
          'command' => 'listProjects',
          'name' => name,
          'listall' => true,
      }
      json = send_request(params)
      json['project'] ? json['project'].first : nil
    end

    ##
    # Lists projects.
            
    def list_projects
      params = {
          'command' => 'listProjects',
          'listall' => true,
      }
      json = send_request(params)
      json['project'] || []
    end

	end

end