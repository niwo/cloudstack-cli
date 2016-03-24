class ComputeOffer < CloudstackCli::Base

  desc 'list', 'list compute offerings'
  option :domain, desc: "the domain associated with the compute offering"
  option :format, default: "table",
    enum: %w(table json yaml)
  option :filter, type: :hash,
    desc: "filter objects based on arrtibutes: (attr1:regex attr2:regex ...)"
  def list
    resolve_domain
    add_filters_to_options("listServiceOfferings") if options[:filter]
    offerings = client.list_service_offerings(options)
    offerings = filter_objects(offerings) if options[:filter]
    if offerings.size < 1
      puts "No offerings found."
    else
      case options[:format].to_sym
      when :yaml
        puts({compute_offers: offerings}.to_yaml)
      when :json
        puts JSON.pretty_generate(compute_offers: offerings)
      else
        print_compute_offerings(offerings)
      end
    end
  end

  desc 'create NAME', 'create compute offering'
  option :cpunumber, required: true
  option :cpuspeed, required: true
  option :displaytext, required: true
  option :memory, required: true
  option :domain
  option :ha, type: :boolean
  option :tags
  def create(name)
    resolve_domain
    options[:name] = name
    say("OK", :green) if client.create_service_offering(options)
  end

  desc 'delete ID', 'delete compute offering'
  def delete(id)
    offerings = client.list_service_offerings(id: id)
    if offerings && offerings.size == 1
      say "Are you sure you want to delete compute offering below?", :yellow
      print_compute_offerings(offerings, false)
      if yes?("[y/N]:", :yellow)
        say("OK", :green) if client.delete_service_offering(id: id)
      end
    else
      say "No offering with ID #{id} found.", :yellow
    end
  end

  desc 'sort', 'sort by cpu and memory grouped by domain'
  def sort
    offerings = client.list_service_offerings
    sortkey = -1
    offerings.group_by{|o| o["domain"]}.each_value do |offers|
      offers.sort {
        |oa, ob| [oa["cpunumber"], oa["memory"]] <=> [ob["cpunumber"], ob["memory"]]
      }.each do |offer|
        puts "#{sortkey.abs} #{offer['domain']} - #{offer["displaytext"]}"
        client.update_service_offering(
          id: offer['id'],
          sortkey: sortkey
        )
        sortkey -= 1
      end
    end
  end

  no_commands do
    def print_compute_offerings(offerings, totals = true)
      table = [%w(Name Displaytext Domain ID)]
      offerings.each do |offering|
        table << [
          offering["name"],
          offering["displaytext"],
          offering["domain"],
          offering["id"]
        ]
      end
      print_table table
      say "Total number of offerings: #{offerings.size}" if totals
    end
  end

end
