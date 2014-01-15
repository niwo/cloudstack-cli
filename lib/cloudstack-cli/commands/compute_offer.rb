class ComputeOffer < CloudstackCli::Base

  desc 'list', 'list compute offerings'
  option :domain
  def list
    offerings = client.list_service_offerings(options[:domain])
    if offerings.size < 1
      puts "No offerings found."
    else
      table = [["Name", "Displaytext", "Domain", "ID"]]
      offerings.each do |offering|
        table << [
          offering["name"],
          offering["displaytext"],
          offering["domain"],
          offering["id"]
        ]
      end
      print_table table
      say "Total number of offerings: #{offerings.size}"
    end
  end

  desc 'create NAME', 'create offering'
  option :cpunumber, required: true
  option :cpuspeed, required: true
  option :displaytext, required: true
  option :memory, required: true
  option :domain
  option :ha, type: :boolean
  option :tags
  def create(name)
    options[:name] = name
    puts "OK" if client.create_offering(options)
  end

  desc 'delete ID', 'delete offering'
  def delete(id)
    puts "OK" if client.delete_offering(id)
  end

  desc 'sort', 'sort by cpu and memory grouped by domain'
  def sort
    offerings = client.list_service_offerings(options[:domain])
    sortkey = -1
    offerings.group_by{|o| o["domain"]}.each_value do |offers|
      offers.sort {
        |oa, ob| [oa["cpunumber"], oa["memory"]] <=> [ob["cpunumber"], ob["memory"]]
      }.each do |offer|
        puts "#{sortkey.abs} #{offer['domain']} - #{offer["displaytext"]}"
        client.update_offering({
          "id" => offer['id'],
          'sortkey' => sortkey
        })
        sortkey -= 1
      end
    end
  end

end