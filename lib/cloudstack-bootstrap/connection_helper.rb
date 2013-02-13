module CloudstackClient
  class ConnectionHelper
    def self.load_configuration(config_file = File.join(File.dirname(__FILE__), '..', '..', 'config', 'cloudstack.yml'))
      begin
        return YAML::load(IO.read(config_file))
      rescue Exception => e
        puts "Unable to load '#{config_file}' : #{e}".color(:red)
        exit
      end
    end
  end
end
