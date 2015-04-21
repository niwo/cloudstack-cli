module CloudstackCli
  module OptionResolver

    def vm_options_to_params
      resolve_zone
      resolve_project
      resolve_compute_offering
      resolve_template
      resolve_disk_offering
      resolve_disk_iso
      unless options[:template_id]
        say "Error: Template or ISO is required.", :red
        exit 1
      end
      resolve_networks
    end

    def resolve_zone
      zones = client.list_zones
      zone = options[:zone] ? zones.find {|z| z['name'] == options[:zone] } : zones.first
      if !zone
        msg = options[:zone] ? "Zone '#{options[:zone]}' is invalid." : "No zone found."
        say "Error: #{msg}", :red
        exit 1
      end
      options[:zone_id] = zone['id']
      options
    end

    def resolve_domain
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

    def resolve_project
      if options[:project]
        if %w(ALL -1).include? options[:project]
          options[:project_id] = "-1"
        elsif project = client.list_projects(name: options[:project]).first
          options[:project_id] = project['id']
        else
          say "Error: Project #{options[:project]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_account
      if options[:account]
        if account = client.list_accounts(name: options[:account]).first
          options[:account_id] = account['id']
        else
          say "Error: Account #{options[:account]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_networks
      networks = []
      if options[:networks]
        options[:networks].each do |name|
          network = client.list_networks(
            name: name,
            zone_id: options[:zone_id],
            project_id: options[:project_id]
          ).first
          if !network
            say "Error: Network '#{name}' not found.", :red
            exit 1
          end
          networks << network
        end
      end
      if networks.empty?
        #unless default_network = client.list_networks(project_id: options[:project_id]).find {
        #  |n| n['isdefault'] == true }
        unless default_network = client.list_networks(project_id: options[:project_id]).first
          say "Error: No default network found.", :red
          exit 1
        end
        networks << default_network
      end
      options[:network_ids] = networks.map {|n| n['id']}.join(',')
      options
    end

    def resolve_iso
      if options[:iso]
        unless iso = client.list_isos(name: options[:iso]).first
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

    def resolve_template
      if options[:template]
        if template = client.list_templates(name: options[:template], template_filter: "all").first
          options[:template_id] = template['id']
        else
          say "Error: Template #{options[:template]} not found.", :red
          exit 1
        end
      end
      options
    end

    def resolve_compute_offering
      if offering = client.list_service_offerings(name: options[:offering]).first
        options[:service_offering_id] = offering['id']
      else
        say "Error: Offering #{options[:offering]} not found.", :red
        exit 1
      end
      options
    end

    def resolve_disk_offering
      if options[:disk_offering]
        unless disk_offering = client.list_disk_offerings(name: options[:disk_offering]).first
          say "Error: Disk offering '#{options[:disk_offering]}' is invalid.", :red
          exit 1
        end
        options[:diskoffering_id] = disk_offering['id']
      end
      options
    end

  end
end
