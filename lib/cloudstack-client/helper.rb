module CloudstackClient
  class ConnectionHelper
    def self.load_configuration(config_file)
      begin
        return YAML::load(IO.read(config_file))
      rescue Exception => e
        $stderr.puts "Can't find the config file '#{config_file}'"
        $stderr.puts "Please see https://bitbucket.org/swisstxt/cloudstack-cli under 'Setup'"
        exit
      end
    end
  end
end
