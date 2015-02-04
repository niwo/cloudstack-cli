class Account < CloudstackCli::Base

  TYPES = {
    0 => 'user',
    1 => 'domain-admin',
    2 => 'admin'
  }

  desc "show NAME", "show detailed infos about an account"
  def show(name)
    accounts = client.list_accounts(name: name)
    if accounts.size < 1
      say "No account named \"#{name}\" found.", :red
    else
      account = accounts.first
      account.delete 'user'
      account['accounttype'] = "#{account['accounttype']} (#{TYPES[account['accounttype']]})"
      table = account.map do |key, value|
        [ set_color("#{key}", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

  desc 'list [NAME]', 'list accounts (by name)'
  def list(name = nil)
    accounts = client.list_accounts(name: name)
    if accounts.size < 1
      puts "No accounts found."
    else
      table = [["Name", "Type", "Domain"]]
      accounts.each do |account|
        table << [account['name'], TYPES[account['accounttype']], account['domain']]
      end
      print_table table
      say "Total number of accounts: #{accounts.size}"
    end
  end

end
