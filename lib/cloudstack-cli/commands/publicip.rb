class Publicip < CloudstackCli::Base

  desc "remove ID", "remove public IP address"
  def remove(id)
    cs_cli = CloudstackCli::Helper.new(options[:config])
    puts "OK" if client.disassociate_ip_address(id)
  end

end