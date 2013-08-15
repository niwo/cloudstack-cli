module CloudstackClient

	module Pod

		##
    # Lists pods.

    def list_pods(args = {})
      params = {
        'command' => 'listPods',
      }

      json = send_request(params)
      json['pod'] || []
    end

	end

end