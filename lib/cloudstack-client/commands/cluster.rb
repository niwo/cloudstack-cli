module CloudstackClient

	module Cluster

		##
    # Lists clusters.

    def list_clusters(args = {})
      params = {
        'command' => 'listClusters',
      }

      json = send_request(params)
      json['cluster'] || []
    end

	end

end