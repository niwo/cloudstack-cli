class Host < CloudstackCli::Base

  desc 'list', 'list hosts'
  option :zone, desc: "lists hosts by zone"
  option :type, desc: "the host type"
  def list
    resolve_zone if options[:zone]
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

  desc 'show', 'show host details'
  def show(name)
    unless host = client.list_hosts(name: name).first
      say "No host with name '#{name}' found."
    else
      table = host.map do |key, value|
        [ set_color("#{key}:", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

end
