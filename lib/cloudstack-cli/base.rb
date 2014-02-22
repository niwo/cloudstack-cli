require "thor"
require "yaml"

module CloudstackCli  
  class Base < Thor
    include Thor::Actions
    include CloudstackCli::Helper
    
    attr_reader :config

    # catch control-c and exit
    trap("SIGINT") {
      puts " bye"
      exit!
    }

    # exit with return code 1 in case of a error
    def self.exit_on_failure?
      true
    end

    no_commands do  
      def client(opts = {})
        @config ||= load_configuration
        @client ||= CloudstackClient::Connection.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key],
          opts.merge({debug: options[:debug]})
        )
      end

      def load_configuration(config_file = options[:config_file], env = options[:env])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run \'cs setup\' to create one."
          exit 1
        end

        begin
          config = YAML::load(IO.read(config_file))
        rescue
          say "Can't load configuration from file #{config_file}.", :red
          exit 1
        end
        
        env ||= config[:default]
        if env
          unless config = config[env]
            say "Can't find environment #{env}.", :red
            exit 1
          end
        end

        unless config.key?(:url) && config.key?(:api_key) && config.key?(:secret_key)
          say "The environment #{env || '\'-\''} contains no valid data.", :red
          say "Please check with 'cs environment list' and set a valid default environment."
          exit 1
        end
        config
      end

      def find_project(name = options[:project], allow_all = true)
        return nil unless name
        if allow_all && %w(ALL -1).include?(name)
          return {'id' => '-1'} 
        end
        unless project = client.get_project(name)
          say "Project '#{name}' not found", :red
          exit 1
        end
        project
      end

      def filter_by(objects, key, value)
        objects.select {|r| r[key].downcase == value.downcase}
      end
    end
  end
end