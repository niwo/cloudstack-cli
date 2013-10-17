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

      def load_configuration(config_file = options[:config], env = options[:environment])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run \'cs setup\' to create one."
          exit 1
        end
        begin
          config = YAML::load(IO.read(config_file))
        rescue
          error "Can't load configuration from file #{config_file}."
          exit 1
        end
        if env
          config = config[env]
          unless config
            error "Can't find environment #{env} in configuration file."
            exit 1
          end
        end
        config
      end

      def find_project(project_name = options[:project])
        return nil unless project_name
        unless project = client.get_project(project_name)
          say "Project '#{options[:project]}' not found", :red
          exit 1
        end
        project
      end

      def filter_by(objects, tag_name, tag)
        objects.select {|r| r[tag_name].downcase == tag.downcase}
      end
    end
  end
end