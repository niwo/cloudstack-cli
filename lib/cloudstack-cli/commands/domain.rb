class Domain < CloudstackCli::Base

  desc 'list', 'list domains'
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    domains = client.list_domains
    if domains.size < 1
      puts "No domains found."
    else
      case options[:format].to_sym
      when :yaml
        puts({domains: domains}.to_yaml)
      when :json
        puts JSON.pretty_generate(domains: domains)
      else
        table = [%w(Name Path)]
        domains.each do |domain|
          table << [domain['name'], domain['path']]
        end
        print_table table
        say "Total number of domains: #{domains.size}"
      end
    end
  end

  desc 'create', 'create domain'
  option :network_domain, desc: "Network domain for networks in the domain."
  option :parent_domain, desc: "Assigns new domain a parent domain by domain name of the parent. If no parent domain is specied, the ROOT domain is assumed."
  def create(name)
    create_domains([options.merge(name: name)])
  end

  desc 'delete', 'delete domain'
  option :parent_domain, desc: "Parent domain by domain name of the parent. If no parent domain is specied, the ROOT domain is assumed."
  def delete(name)
    delete_domains([options.merge(name: name)])
  end

  no_commands do

    def create_domains(domains)
      puts domains
      domains.each do |domain|
        say "Creating domain '#{domain['name']}'... "

        if dom = client.list_domains(name: domain["name"], listall: true).first
          unless domain["parent_domain"] && dom['parentdomainname'] != domain["parent_domain"]
            say "domain '#{domain["name"]}' already exists.", :yellow
            next
          end
        end

        if domain["parent_domain"]
          parent = client.list_domains(name: domain["parent_domain"], listall: true).first
          unless parent
            say "parent domain '#{domain["parent_domain"]}' of domain '#{domain["name"]}' not found.", :yellow
            next
          end
          domain['parentdomain_id'] = parent['id']
        end

        client.create_domain(domain) ? say("OK.", :green) : say("Failed.", :red)
      end
    end

    def delete_domains(domains)
      domains.each do |domain|
        print "Deleting domain '#{domain['name']}'..."
        if dom = client.list_domains(name: domain["name"], listall: true).first
          if domain["parent_domain"] && dom['parentdomainname'] =! domain["parent_domain"]
            say "domain '#{domain["name"]}' with same name found, but parent_domain '#{domain["parent_domain"]}' does not match.", :yellow
            next
          end
          client.delete_domain(id: dom['id']) ? say(" OK.", :green) : say(" Failed.", :red)
        else
          say "domain '#{domain["name"]}' not found.", :yellow
        end
      end
    end

  end

end
