class Offering < Thor
  include CommandLineReporter

  desc 'list', 'list offerings by type [compute|network|storage]'
  option :domain
  def list(type='compute')
    cs_cli = CloudstackCli::Helper.new
    offerings = cs_cli.server_offerings(options[:domain])
    if offerings.size < 1
      puts "No offerings found"
    else
      table(border: true) do
        row do
          column 'Name', width: 20
          column 'Description', width: 30
          column 'Domain', width: 16
        end
        offerings.each do |offering|
          row do
            column offering["name"]
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
  option :ha
  option :tags
  def create(name)
    options[:name] = name

    
  end

end