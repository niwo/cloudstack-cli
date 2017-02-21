class User < CloudstackCli::Base

  desc 'list', 'list users'
  option :listall, type: :boolean, default: true
  option :account
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_account
    users = client.list_users(options)
    if users.size < 1
      say "No users found."
    else
      case options[:format].to_sym
      when :yaml
        puts({users: users}.to_yaml)
      when :json
        puts JSON.pretty_generate(users: users)
      else
        table = [%w(Account Type Name Username Email State Domain)]
        users.each do |user|
          table << [
            user['account'],
            Account::TYPES[user['accounttype']],
            "#{user['firstname']} #{user['lastname']}",
            user['username'], user['email'],
            user['state'], user['domain']
          ]
        end
        print_table table
        say "Total number of users: #{users.size}"
      end
    end
  end

end
