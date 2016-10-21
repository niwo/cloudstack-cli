class Capacity < CloudstackCli::Base
  CAPACITY_TYPES = {
    0 => {name: "Memory", unit: "GB", divider: 1024.0**3},
    1 => {name: "CPU", unit: "GHz", divider: 1000.0},
    2 => {name: "Storage", unit: "TB", divider: 1024.0**4},
    3 => {name: "Primary Storage", unit: "TB", divider: 1024.0**4},
    4 => {name: "Public IP's"},
    5 => {name: "Private IP's"},
    6 => {name: "Secondary Storage", unit: "TB", divider: 1024.0**4},
    7 => {name: "VLAN"},
    8 => {name: "Direct Attached Public IP's"},
    9 => {name: "Local Storage", unit: "TB", divider: 1024.0**4}
  }

  desc "list", "list system capacity"
  option :zone, desc: "list capacity by zone"
  option :cluster, desc: "list capacity by cluster"
  option :type, desc: "specify type, see types for a list of types"
  def list
    resolve_zone
    resolve_cluster
    capacities = client.list_capacity(options)
    table = []
    header = ["Zone", "Type", "Capacity Used", "Capacity Total", "Used"]
    header[0] = "Cluster" if options[:cluster_id]
    capacities.each do |c|
      if CAPACITY_TYPES.include? c['type']
        table << [
          c['clustername'] || c['zonename'],
          CAPACITY_TYPES[c['type']][:name],
          capacity_to_s(c, 'capacityused'),
          capacity_to_s(c, 'capacitytotal'),
          "#{c['percentused']}%"
        ]
      end
    end
    table = table.sort {|a, b| [a[0], a[1]] <=> [b[0], b[1]]}
    print_table table.insert(0, header)
  end

  desc "types", "show capacity types"
  def types
    table = [['type', 'name']]
    CAPACITY_TYPES.each_pair do |type, data|
      table << [type, data[:name]]
    end
    print_table table
  end

  no_commands do

    def capacity_to_s(capacity, entity)
      value = CAPACITY_TYPES[capacity['type']][:divider] ?
        (capacity[entity] / CAPACITY_TYPES[capacity['type']][:divider]).round(1) :
        capacity[entity]
      CAPACITY_TYPES[capacity['type']][:unit] ?
        "#{value} #{CAPACITY_TYPES[capacity['type']][:unit]}" :
        value.to_s
    end

  end

end
