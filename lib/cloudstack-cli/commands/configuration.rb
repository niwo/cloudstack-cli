class Configuration < CloudstackCli::Base

  desc 'list', 'list configurations'
  option :name, desc: "lists configuration by name"
  option :category, desc: "lists configurations by category"
  option :keyword, desc: "lists configuration by keyword"
  def list
    configs = client.list_configurations(options)
    if configs.size < 1
      say "No configuration found."
    else
      table = [%w(Name Category Value)]
      configs.each do |config|
        table << [
          config['name'],
          config['category'],
          config['value']
        ]
      end
      print_table table
      say "Total number of configurations: #{configs.size}"
    end
  end

end
