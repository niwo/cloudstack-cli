class Domain < Thor

  desc 'list [NAME]', 'list domains'
  def list(name = nil)
    cs_cli = CloudstackCli::Helper.new(options[:config])
    domains = cs_cli.domains(name)
    if domains.size < 1
      puts "No domains found"
    else
      domains.each do |domain|
        puts "#{domain['name']}"
      end
    end
  end
  
end