class Account < Thor

  desc 'account list [NAME]', 'list accounts'
  def list(name = nil)
    cs_cli = CloudstackCli::Helper.new(options[:config])
    accounts = cs_cli.list_accounts(name)
    if accounts.size < 1
      puts "No accounts found"
    else
      accounts.each do |account|
        puts "#{account['name']} - #{account['domain']}"
      end
    end
  end
  
end