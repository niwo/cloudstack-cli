class Publicip < Thor

  desc "publicip remove ID", "remove public IP address"
  def remove(id)
    cs_cli = CloudstackCli::Helper.new(options[:config])
    puts "OK" if cs_cli.remove_publicip(id)
  end

end