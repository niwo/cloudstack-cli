class Offering < Thor
  include CommandLineReporter

  desc 'list', 'list offerings by type [compute|network|storage]'
  option :domain
  def list(type='compute')
    cs_cli = CloudstackCli::Helper.new
    offerings = cs_cli.server_offerings(options[:domain])

    offerings.group_by{|o| o["domain"]}.each_value do |offers|
      offers.sort {
        |oa, ob| [oa["cpunumber"], oa["memory"]] <=> [ob["cpunumber"], ob["memory"]]
      }.each do |offer|
        puts "#{offer['domain']} - #{offer["displaytext"]}"
      end
    end

    if offerings.size < 1
      puts "No offerings found"
    else
      table(border: true) do
        row do
          column 'Name', width: 20
          column 'Description', width: 30
          column 'ID', width: 30
          column 'Domain', width: 16
        end
        offerings.each do |offering|
          row do
            column offering["name"]
            column offering["id"]
            column offering["displaytext"]
            column offering["domain"]
          end
        end
      end
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
    cs_cli = CloudstackCli::Helper.new
    puts "OK" if cs_cli.create_offering(options)
  end

  desc 'delete ID', 'delete offering'
  def delete(id)
    cs_cli = CloudstackCli::Helper.new
    puts "OK" if cs_cli.delete_offering(id)
  end


  desc 'sort', 'sort by cpu and memory grouped by domain'
  def sort
    cs_cli = CloudstackCli::Helper.new
    offerings = cs_cli.server_offerings(options[:domain])
    sortkey = -1
    offerings.group_by{|o| o["domain"]}.each_value do |offers|
      offers.sort {
        |oa, ob| [oa["cpunumber"], oa["memory"]] <=> [ob["cpunumber"], ob["memory"]]
      }.each do |offer|
        puts "#{sortkey.abs} #{offer['domain']} - #{offer["displaytext"]}"
        cs_cli.update_offering({
          "id" => offer['id'],
          'sortkey' => sortkey
        })
        sortkey -= 1
      end
    end
  end

end