class ResourceLimit < CloudstackCli::Base
  RESOURCE_TYPES = {
    0  => {name: "Instances"},
    1  => {name: "IP Addresses"},
    2  => {name: "Volumes"},
    3  => {name: "Snapshots"},
    4  => {name: "Templates"},
    5  => {name: "Projects"},
    6  => {name: "Networks"},
    7  => {name: "VPC's"},
    8  => {name: "CPU's"},
    9  => {name: "Memory", unit: "GB", divider: 1024.0},
    10 => {name: "Primary Storage", unit: "TB", divider: 1024.0},
    11 => {name: "Secondary Storage", unit: "TB", divider: 1024.0}
  }

  desc "list", "list resource limits"
  option :account
  option :project
  option :type, desc: "specify type, see types for a list of types"
  def list
    limits = client.list_resource_limits(options)
    table = []
    header = options[:project] ? ["Project"] : ["Account"]
    header += ["Type", "Resource Name", "Max"]
    limits.each do |limit|
      limit['resourcetype'] = limit['resourcetype'].to_i
      table << [
        options[:project] ? limit['project'] : limit['account'],
        limit['resourcetype'],
        RESOURCE_TYPES[limit['resourcetype']][:name],
        resource_to_s(limit, 'max')
      ]
    end
    table = table.insert(0, header)
    print_table table
  end

  desc "types", "show resource types"
  def types
    table = [['type', 'name']]
    RESOURCE_TYPES.each_pair do |type, data|
      table << [type, data[:name]]
    end
    print_table table
  end

  no_commands do

    def resource_to_s(limit, entity)
      value = RESOURCE_TYPES[limit['resourcetype']][:divider] ?
      (limit[entity] / RESOURCE_TYPES[limit['resourcetype']][:divider]).round(1) :
      limit[entity]
      RESOURCE_TYPES[limit['resourcetype']][:unit] ?
      "#{value} #{RESOURCE_TYPES[limit['resourcetype']][:unit]}" :
      value.to_s
    end

  end

end
