class Capacity < CloudstackCli::Base

  desc "list", "list system capacity"
  option :zone
  def list
    puts JSON.pretty_generate(cloudstack_client.list_capacity)
  end

end