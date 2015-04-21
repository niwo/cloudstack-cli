class User < CloudstackCli::Base

  desc 'list', 'list users'
  option :listall
  option :account
  def list
    resolve_account
    users = client.list_users(options)
    if users.size < 1
      say "No users found."
    else
      table = [["Account", "Type", "Name", "Email", "State", "Domain"]]
      users.each do |user|
        table << [
          user['account'], Account::TYPES[user['accounttype']], "#{user['firstname']} #{user['lastname']}",
          user['email'], user['state'], user['domain']
        ]
      end
      print_table table
      say "Total number of users: #{users.size}"
    end
  end

end
