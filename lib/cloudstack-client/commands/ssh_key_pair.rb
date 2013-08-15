module CloudstackClient

	module SshKeyPair

		##
    # Lists ssh key pairs.
    #

    def list_ssh_key_pairs(args = {})
      params = {
          'command' => 'listSSHKeyPairs',
          'isrecursive' => true
      }
      params['listall'] = true if args[:listall]
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
      
      json = send_request(params)
      json['sshkeypair'] || []
    end

    ##
    # Create ssh key pairs.
    #

    def create_ssh_key_pair(name, args = {})
      params = {
          'command' => 'createSSHKeyPair',
          'name' => name
      }
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
      
      json = send_request(params)['keypair']
    end

    ##
    # Delete ssh key pairs.
    #

    def delete_ssh_key_pair(name, args = {})
      params = {
          'command' => 'deleteSSHKeyPair',
          'name' => name
      }

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
      
      json = send_request(params)
    end

	end

end