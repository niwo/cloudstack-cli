class Volume < CloudstackCli::Base

  desc "list", "list volumes"
  option :project, desc: 'list resources by project'
  option :account, desc: 'list resources by account'
  option :zone, desc: "the name of the availability zone"
  option :keyword, desc: 'list by keyword'
  option :name, desc: 'name of the disk volume'
  option :type, desc: 'type of disk volume (ROOT or DATADISK)'
  def list
    resolve_project
    resolve_account
    resolve_zone
    volumes = client.list_volumes(options)
    if volumes.size < 1
      say "No volumes found."
    else
      table = [%w(Name Type Size VM Storage Offeringname Zone Status)]
      table.first << 'Project' if options[:project]
      volumes.each do |volume|
        table << [
          volume['name'], volume['type'],
          (volume['size'] / 1024**3).to_s + 'GB',
          volume['vmname'],
          volume['storage'],
          volume['diskofferingname'],
          volume['zonename'],
          volume['state']
        ]
        table.last << volume['project'] if options[:project]
      end
      print_table(table)
      say "Total number of volumes: #{volumes.size}"
    end
  end

  desc "show NAME", "show volume details"
  option :project, desc: 'project of volume'
  def show(name)
    resolve_project
    options[:listall] = true
    options[:name] = name
    volumes = client.list_volumes(options)
    if volumes.size < 1
      say "No volume with name \"#{name}\" found."
    else
      volume = volumes.first
      table = volume.map do |key, value|
        [ set_color("#{key}:", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

  desc "create NAME", "create volume"
  option :project,
    desc: "project of volume"
  option :disk_offering,
    desc: "disk offering for the disk volume. Either disk_offering or snapshot must be passed in"
  option :snapshot,
    desc: "snapshot for the disk volume. Either disk_offering or snapshot must be passed in"
  option :virtual_machine,
    desc: "Used together with the snapshot option: VM to which the volume gets attached after creation."
  option :zone,
    desc: "name of the availability zone"
  option :size,
    desc: "size of the volume in GB"
  def create(name)
    options[:name] = name
    resolve_project
    resolve_zone
    resolve_disk_offering
    resolve_snapshot
    resolve_virtual_machine

    if !options[:disk_offering_id] && !options[:snapshot_id]
      say "Either disk_offering or snapshot must be passed in.", :yellow
      exit 1
    elsif options[:disk_offering_id] && !options[:zone_id]
      say "Zone is required when deploying with disk-offering.", :yellow
      exit 1
    end

    say "Creating volume #{name} "
    job = client.create_volume(options).merge(sync: true)
    say " OK.", :green

    # attach the new volume if a vm is profided and not a sapshot
    if options[:virtual_machine] && options[:snapshot] == nil
      sleep 2
      say "Attach volume #{name} to VM #{options[:virtual_machine]} "
      client.attach_volume(
        id: job['volume']['id'],
        virtualmachineid: options[:virtual_machine_id],
        sync: true
      )
      say " OK.", :green
    end
  end

  desc "attach NAME", "attach volume to VM"
  option :project, desc: 'project of volume'
  option :virtual_machine, desc: 'virtual machine of volume'
  def attach(name)
    resolve_project
    resolve_virtual_machine

    volume = client.list_volumes(
      name: name,
      listall: true,
      project_id: options[:project_id]
    ).first

    if !volume
      say "Error: Volume #{name} not found.", :red
      exit 1
    elsif volume.has_key?("virtualmachineid")
      say "Error: Volume #{name} already attached to VM #{volume["vmname"]}.", :red
      exit 1
    end

    say "Attach volume #{name} to VM #{options[:virtual_machine]} "
    client.attach_volume(
      id: volume['id'],
      virtualmachine_id: options[:virtual_machine_id]
    )
    say " OK.", :green
  end

  desc "detach NAME", "attach volume to VM"
  option :project, desc: 'project of volume'
  def detach(name)
    resolve_project

    volume = client.list_volumes(
      name: name,
      listall: true,
      project_id: options[:project_id]
    ).first

    if !volume
      say "Error: Volume #{name} not found.", :red
      exit 1
    elsif !volume.has_key?("virtualmachineid")
      say "Error: Volume #{name} currently not attached to any VM.", :red
      exit 1
    end

    say "Detach volume #{name} from VM #{volume["vmname"]} "
    client.detach_volume id: volume['id']
    say " OK.", :green
  end

  desc "delete NAME", "attach volume to VM"
  option :project, desc: 'project of volume'
  def delete(name)
    resolve_project

    volume = client.list_volumes(
      name: name,
      listall: true,
      project_id: options[:project_id]
    ).first

    if !volume
      say "Error: Volume #{name} not found.", :red
      exit 1
    elsif volume.has_key?("virtualmachineid")
      say "Error: Volume #{name} must be detached before deletion.", :red
      exit 1
    end

    say "Delete volume #{name} "
    client.delete_volume id: volume['id']
    say " OK.", :green
  end

end
