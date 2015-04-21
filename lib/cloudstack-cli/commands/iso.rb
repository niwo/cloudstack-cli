class Iso < CloudstackCli::Base

  desc 'list', "list iso's"
  option :project
  option :zone
  option :account
  option :isofilter,
    enum: %w(all featured self self-executable executable community)
  def list
    resolve_project
    resolve_zone
    resolve_account
    isos = client.list_isos(options)
    if isos.size < 1
      puts "No iso's found"
    else
      table = [%w(Name Zone Bootable Public Featured)]
      isos.each do |iso|
        table <<  [
          iso['name'],
          iso['zonename'],
          iso['bootable'],
          iso['ispublic'],
          iso['isfeatured']
        ]
      end
      print_table(table)
      say "Total number of isos: #{isos.size}"
    end
  end

  desc 'detach VM_ID', "detaches any ISO file (if any) currently attached to a virtual machine"
  def detach(vm_id)
    client.detach_iso({virtualmachine_id: vm_id}, {sync: true})
    say " OK", :green
  end

end
