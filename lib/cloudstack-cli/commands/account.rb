class Account < CloudstackCli::Base

  TYPES = {
    0 => 'user',
    1 => 'domain-admin',
    2 => 'admin'
  }

  desc 'list [NAME]', 'list accounts'
  def list(name = nil)
    accounts = client.list_accounts({name: name})
    if accounts.size < 1
      puts "No accounts found."
    else
      table = [["Name", "Type", "Domain"]]
      accounts.each do |account|
        table << [account['name'], TYPES[account['accounttype']], account['domain']]
      end
      print_table table
    end
  end
  
end