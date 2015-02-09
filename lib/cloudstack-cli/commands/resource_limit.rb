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

  desc "refresh", "refresh resource counts"
  option :domain, desc: "refresh resource for a specified domain"
  option :account, desc: "refresh resource for a specified account"
  option :project, desc: "refresh resource for a specified project"
  option :type, desc: "specify type, see types for a list of types"
  def refresh
    set_domain_id if options[:domain]
    options[:resource_type] = options[:type] if options[:type]

    unless ['domain_id', 'account', 'project'].any? {|k| options.key?(k)}
      say "Error: Please provide domain, account or project.", :red
      exit 1
    end

    if resource_count = client.update_resource_count(options)
      say "Sucessfully refreshed resource limits.", :green
    else
      say "Error refreshing resource limits.", :red
      exit 1
    end
  end

  desc "update", "update resource counts"
  option :domain, desc: "update resource for a specified domain"
  option :account, desc: "update resource for a specified account"
  option :project, desc: "update resource for a specified project"
  option :type,
    desc: "specify type, see types for a list of types",
    required: true
  option :max,
    desc: "Maximum resource limit.",
    required: true
  def update
    set_domain_id if options[:domain]
    options[:resource_type] = options[:type]

    unless ['domain_id', 'account', 'project'].any? {|k| options.key?(k)}
      say "Error: Please provide domain, account or project.", :red
      exit 1
    end

    if resource_count = client.update_resource_limit(options)
      say "Sucessfully updated resource limits.", :green
    else
      say "Error updating resource limits.", :red
      exit 1
    end
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
      return '-1 (unlimited)' if limit['max'] == -1
      value = RESOURCE_TYPES[limit['resourcetype']][:divider] ?
      (limit[entity] / RESOURCE_TYPES[limit['resourcetype']][:divider]).round(1) :
      limit[entity]
      RESOURCE_TYPES[limit['resourcetype']][:unit] ?
      "#{value} #{RESOURCE_TYPES[limit['resourcetype']][:unit]}" :
      value.to_s
    end

    def set_domain_id
      domains = client.list_domains(options[:domain])
      if domains.size < 1
        say "Domain #{options[:domain]} not found.", :red
        exit -1
      else
        options[:domain_id] = domains.first['id']
      end
    end

  end

end
