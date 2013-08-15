module CloudstackClient

	module User

		##
    # Lists users.
    #

    def list_users(args = {})
      params = {
          'command' => 'listUsers',
          'isrecursive' => true
      }
      params['listall'] = true if args[:listall]
      
      if args[:account]
        account = list_accounts({name: args[:account]}).first
        unless account
          puts "Error: Account #{args[:account]} not found."
          exit 1
        end
        params['domainid'] = account["domainid"]
        params['account'] = args[:account]
      end
      
      json = send_request(params)
      json['user'] || []
    end

	end

end