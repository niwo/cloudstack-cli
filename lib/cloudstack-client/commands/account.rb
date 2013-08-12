module CloudstackClient

	module Account

		##
    # Lists accounts.

    def list_accounts(args = { :name => nil })
      params = {
        'command' => 'listAccounts',
        'listall' => 'true',
        'isrecursive' => 'true'
      }
      params['name'] = args[:name] if args[:name]

      json = send_request(params)
      json['account'] || []
    end

	end

end