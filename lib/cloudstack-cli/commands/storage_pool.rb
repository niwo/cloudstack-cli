class StoragePool < CloudstackCli::Base

  desc 'list', 'list storage_pools'
  option :zone, desc: "zone name for the storage pool"
  option :name, desc: "name of the storage pool"
  option :keyword, desc: "list by keyword"
  option :state, desc: "filter by state (Up, Maintenance)"
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_zone
    storage_pools = client.list_storage_pools(options)
    if storage_pools.size < 1
      say "No storage pools found."
    else
      case options[:format].to_sym
      when :yaml
        puts({storage_pools: storage_pools}.to_yaml)
      when :json
        puts JSON.pretty_generate(storage_pools: storage_pools)
      else
        storage_pools = filter_by(storage_pools, "state", options[:state]) if options[:state]
        table = [%w(Name Pod State Zone)]
        table[0] << "Size [GB]"
        table[0] << "Used [GB]"
        table[0] << "Used [%]"
        table[0] << "Alocated [GB]"
        table[0] << "Alocated [%]"
        table[0] << "Type"
        storage_pools.each do |storage_pool|
          total = storage_pool['disksizetotal'] / 1024**3
          used = (storage_pool['disksizeused'] / 1024**3) rescue 0
          allocated = (storage_pool['disksizeallocated'] / 1024**3) rescue 0
          table << [
          	storage_pool['name'], storage_pool['podname'],
            storage_pool['state'], storage_pool['zonename'],
            total, used, (100.0 / total * used).round(0),
            allocated, (100.0 / total * allocated).round(0),
            storage_pool['type']
          ]
        end
        print_table table
        say "Total number of storage_pools: #{storage_pools.size}"
      end
    end
  end

end
