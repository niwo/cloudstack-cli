class Configuration < CloudstackCli::Base

  desc 'list', 'list configurations'
  option :name
  option :category
  option :keyword
  def list
    configs = client.list_configurations(options)
    if configs.size < 1
      say "No configuration found."
    else
      table = [%w(Name Scope Category Value)]
      configs.each do |config|
        table << [
          config['name'],
          config['scope'],
          config['category'],
          config['value']
        ]
      end
      print_table table
      say "Total number of configurations: #{configs.size}"
    end
  end

end