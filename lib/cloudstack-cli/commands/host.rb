class Host < CloudstackCli::Base

  desc 'list', 'list hosts'
  option :zone
  def list
    hosts = client.list_hosts(options)
    if hosts.size < 1
      say "No hosts found."
    else
      table = [["Zone", "Type", "Cluster", "Name"]]
      hosts.each do |host|
        table << [
        	host['zonename'], host['type'], host['clustername'], host['name']
        ]
      end
      print_table table
      say "Total number of hosts: #{hosts.size}"
    end
  end

end