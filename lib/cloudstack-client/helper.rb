module CloudstackClient
  class ConnectionHelper
    def self.load_configuration(config_file)
      begin
        return YAML::load(IO.read(config_file))
      rescue Exception => e
        $stderr.puts "Can't find the config file #{config_file}."
        $stderr.puts "To create a new configuration file run \"cs setup\"."
        exit
      end
    end
  end
end
