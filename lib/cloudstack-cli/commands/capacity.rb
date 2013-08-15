class Capacity < CloudstackCli::Base
	CAPACITY_TYPES = {
		0 => "Memory",
		1 => "CPU",
		2 => "Storage",
		3 => "Storage Allocated",
		4 => "Public IP's",
		5 => "Private IP's",
		6 => "Secondary Storage",
		7 => "VLAN",
		8 => "Direct Attached Public IP's",
		9 => "Local Storage"
	}

  desc "list", "list system capacity"
  option :zone
  def list
  	capacities = client.list_capacity
  	table = []
    header = ["Zone", "Type", "Capacity Used", "Capacity Total", "Used"]
    capacities.each do |c|
    	table << [
    		c['zonename'],
    	 	CAPACITY_TYPES[c['type']],
    	 	c['capacityused'],
    	 	c['capacitytotal'],
    	 	"#{c['percentused']}%"
    	]
    end
    table = table.sort {|a, b|  [a[0], a[1]] <=> [b[0], b[1]]}.insert(0, header)
    print_table table
  end

end