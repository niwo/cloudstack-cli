class Offering < Thor

  desc 'list', 'list offerings by type [compute|network|storage]'
  def list(type='compute')
    cs_cli = CloudstackCli::Cli.new
    offerings = cs_cli.server_offerings
    if offerings.size < 1
      puts "No offerings found"
    else
      offerings.each do |offering|
        puts "#{offering['name']} - #{offering['displaytext']} - #{offering['domain']}"
      end
    end
  end
end