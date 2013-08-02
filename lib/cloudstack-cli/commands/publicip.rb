class PublicIp < CloudstackCli::Base

  desc "remove ID", "remove public IP address"
  def remove(id)
    puts "OK" if client.disassociate_ip_address(id)
  end

end