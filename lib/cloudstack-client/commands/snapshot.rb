module CloudstackClient

	module Snapshot

		##
    # Lists snapshots.

    def list_snapshots(args = {})
      params = {
        'command' => 'listSnapshots',
        'isrecursive' => 'true'
      }
      params['name'] = args[:name] if args[:name]

      if args[:project]
        project = get_project(args[:project])
        unless project
          puts "Error: project #{args[:project]} not found."
          exit 1
        end
        params['projectid'] = project['id']
      end
      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end
      params['listall'] = args[:listall] if args[:listall]

      json = send_request(params)
      json['snapshot'] || []
    end

	end

end