module CloudstackCli
  module OptionResolver

    def vm_options_to_params(options = options)
      resolve_zone(options)
      resolve_project(options)
      resolve_compute_offering(options)
      resolve_template(options)
      resolve_disk_offering(options)
      resolve_iso(options)
      unless options[:template_id]
        say "Error: Template or ISO is required.", :red
        exit 1
      end
      resolve_networks(options)
    end

    def resolve_zone(options = options)
      if options[:zone]
        zones = client.list_zones
        zone = zones.find {|z| z['name'] == options[:zone] }
        if !zone
          msg = options[:zone] ? "Zone '#{options[:zone]}' is invalid." : "No zone found."
          say "Error: #{msg}", :red
          exit 1
        end
        options[:zone_id] = zone['id']
      end
      options
    end

    def resolve_domain(options = options)
      if options[:domain]
        if domain = client.list_domains(name: options[:domain]).first
          options[:domain_id] = domain['id']
        else
          say "Error: Domain #{options[:domain]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_project(options = options)
      if options[:project]
        if %w(ALL -1).include? options[:project]
          options[:project_id] = "-1"
        elsif project = client.list_projects(name: options[:project], listall: true).first
          options[:project_id] = project['id']
        else
          say "Error: Project #{options[:project]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_account(options = options)
      if options[:account]
        if account = client.list_accounts(name: options[:account], listall: true).first
          options[:account_id] = account['id']
          options[:domain_id] = account['domainid']
        else
          say "Error: Account #{options[:account]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_networks(options = options)
      networks = []
      available_networks = network = client.list_networks(
        zone_id: options[:zone_id],
        project_id: options[:project_id]
      )
      if options[:networks]
        options[:networks].each do |name|
          unless network = available_networks.find { |n| n['name'] == name }
            say "Error: Network '#{name}' not found.", :red
            exit 1
          end
          networks << network['id'] rescue nil
        end
      end
      networks.compact!
      if networks.empty?
        #unless default_network = client.list_networks(project_id: options[:project_id]).find {
        #  |n| n['isdefault'] == true }
        unless default_network = client.list_networks(project_id: options[:project_id]).first
          say "Error: No default network found.", :red
          exit 1
        end
        networks << available_networks.first['id'] rescue nil
      end
      options[:network_ids] = networks.join(',')
      options
    end

    def resolve_iso(options = options)
      if options[:iso]
        unless iso = client.list_isos(
            name: options[:iso],
            project_id: options[:project_id]
          ).first
          say "Error: Iso '#{args[:iso]}' is invalid.", :red
          exit 1
        end
        unless options[:diskoffering_id]
          say "Error: a disk offering is required when using iso.", :red
          exit 1
        end
        options[:template_id] = iso['id']
        options['hypervisor'] = (options[:hypervisor] || 'vmware')
      end
      options
    end

    def resolve_template(options = options)
      if options[:template]
        if template = client.list_templates(
            name: options[:template],
            template_filter: "executable",
            project_id: options[:project_id]
          ).first
          options[:template_id] = template['id']
        else
          say "Error: Template #{options[:template]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_compute_offering(options = options)
      if offering = client.list_service_offerings(name: options[:offering]).first
        options[:service_offering_id] = offering['id']
      else
        say "Error: Offering #{options[:offering]} not found.", :red
        exit 1
      end
      options
    end

    def resolve_disk_offering(options = options)
      if options[:disk_offering]
        unless disk_offering = client.list_disk_offerings(name: options[:disk_offering]).first
          say "Error: Disk offering '#{options[:disk_offering]}' not found.", :red
          exit 1
        end
        options[:disk_offering_id] = disk_offering['id']
      end
      options
    end

    def resolve_virtual_machine(options = options)
      if options[:virtual_machine]
        args = { name: options[:virtual_machine], listall: true }
        args[:project_id] = options[:project_id]
        unless vm = client.list_virtual_machines(args).first
          say "Error: VM '#{options[:virtual_machine]}' not found.", :red
          exit 1
        end
        options[:virtual_machine_id] = vm['id']
      end
      options
    end

    def resolve_snapshot(options = options)
      if options[:snapshot]
        args = { name: options[:snapshot], listall: true }
        args[:project_id] = options[:project_id]
        unless snapshot = client.list_snapshots(args).first
          say "Error: Snapshot '#{options[:snapshot]}' not found.", :red
          exit 1
        end
        options[:snapshot_id] = snapshot['id']
      end
      options
    end

  end
end
