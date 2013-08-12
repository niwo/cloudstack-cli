module CloudstackClient

	module Capacity

		##
    # List capacity.

    def list_capacity(args = {})
      params = {
        'command' => 'listCapacity',
      }

      json = send_request(params)
      json['capacity'] || []
    end

	end

end