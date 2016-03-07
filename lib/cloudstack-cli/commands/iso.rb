class Iso < CloudstackCli::Base

  desc 'list', "list ISO's"
  option :project, desc: 'project name'
  option :zone, desc: 'zone name'
  option :account, desc: 'account name'
  option :type, desc: 'type of ISO',
    enum: %w(featured self selfexecutable sharedexecutable executable community all)
  def list
    resolve_project
    resolve_zone
    resolve_account
    options[:isofilter] = options[:type]
    options.delete :type
    isos = client.list_isos(options)
    if isos.size < 1
      puts "No ISO's found."
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
      say "Total number of ISO's: #{isos.size}"
    end
  end

  desc 'attach', "attaches an ISO to a virtual machine"
  option :iso, desc: 'ISO file name'
  option :project, desc: 'project name'
  option :virtual_machine, desc: 'virtual machine name'
  option :virtual_machine_id, desc: 'virtual machine id (if no virtual machine name profided)'
  def attach
    resolve_iso
    resolve_project
    unless options[:virtual_machine_id]
     resolve_virtual_machine
    end
    options[:id] = options[:iso_id]
    client.attach_iso(options.merge(sync: false))
    say " OK", :green
  end

  desc 'detach', "detaches any ISO file (if any) currently attached to a virtual machine"
  option :project, desc: 'project name'
  option :virtual_machine, desc: 'virtual machine name'
  option :virtual_machine_id, desc: 'virtual machine id (if no virtual machine name profided)'
  def detach
    resolve_project
    unless options[:virtual_machine_id]
      resolve_virtual_machine
    end
    client.detach_iso(options.merge(sync: true))
    say " OK", :green
  end

end
