class Account < CloudstackCli::Base

  TYPES = {
    0 => 'user',
    1 => 'domain-admin',
    2 => 'admin'
  }

  desc "show NAME", "show detailed infos about an account"
  def show(name)
    unless account = client.list_accounts(name: name, listall: true).first
      say "No account named \"#{name}\" found.", :red
    else
      account.delete 'user'
      account['accounttype'] = "#{account['accounttype']} (#{TYPES[account['accounttype']]})"
      table = account.map do |key, value|
        [ set_color("#{key}", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

  desc 'list', 'list accounts'
  def list
    accounts = client.list_accounts(listall: true)
    if accounts.size < 1
      puts "No accounts found."
    else
      table = [%w(Name Type Domain State)]
      accounts.each do |account|
        table << [
          account['name'],
          TYPES[account['accounttype']],
          account['domain'],
          account['state']
        ]
      end
      print_table table
      say "Total number of accounts: #{accounts.size}"
    end
  end

end
