class SystemVm < CloudstackCli::Base

  desc 'list', 'list system vms'
  option :zone
  def list
    vms = client.list_system_vms(options)
    if vms.size < 1
      say "No system vms found."
    else
      table = [["Zone", "State", "Type", "Name"]]
      vms.each do |vm|
        table << [
          vm['zonename'], vm['state'], vm['systemvmtype'], vm['name']
        ]
      end
      print_table table
      say "Total number of system vms: #{vms.size}"
    end
  end

end
