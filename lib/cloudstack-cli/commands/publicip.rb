class Publicip < Thor

  desc "remove ID", "remove public IP address"
  def remove(id)
    cs_cli = CloudstackCli::Helper.new
    puts "OK" if cs_cli.remove_publicip(id)
  end

end