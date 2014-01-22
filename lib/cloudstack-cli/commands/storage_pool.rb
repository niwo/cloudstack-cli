class StoragePool < CloudstackCli::Base

  desc 'list', 'list storage_pool'
  option :zone, desc: "zone name for the storage pool"
  option :name, desc: "name of the storage pool"
  option :keyword, desc: "list by keyword" 
  def list
    storage_pools = client.list_storage_pools(options)
    if storage_pools.size < 1
      say "No storage pools found."
    else
      table = [%w(Name Pod_Name State Zone)]
      table[0] << "Size [GB]"
      table[0] << "Used [GB]"
      table[0] << "Used [%]"
      storage_pools.each do |storage_pool|
        total = storage_pool['disksizetotal'] / 1024**3
        used = (storage_pool['disksizeused'] / 1024**3) rescue 0
        table << [
        	storage_pool['name'], storage_pool['podname'],
          storage_pool['state'], storage_pool['zonename'],
          total, used, (100.0 / total * used).round(0)
        ]
      end
      print_table table
      say "Total number of storage_pools: #{storage_pools.size}"
    end
  end

end