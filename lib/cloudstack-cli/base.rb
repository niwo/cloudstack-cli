require "thor"
require "cloudstack-cli/thor_patch"
require "yaml"
require "open-uri"

module CloudstackCli
  class Base < Thor
    include Thor::Actions
    include CloudstackCli::Helper
    include CloudstackCli::OptionResolver

    attr_reader :config

    # rescue error globally
    def self.start(given_args=ARGV, config={})
      super
    rescue => e
      error_class = e.class.name.split('::')
      if error_class.size == 2 && error_class.first == "CloudstackClient"
        puts "\e[31mERROR\e[0m: #{error_class.last} - #{e.message}"
        puts e.backtrace if ARGV.include? "--debug"
      else
        raise
      end
    end

    # catch control-c and exit
    trap("SIGINT") do
      puts
      puts "bye.."
      exit!
    end

    # exit with return code 1 in case of a error
    def self.exit_on_failure?
      true
    end

    no_commands do
      def client
        @config ||= load_configuration
        @client ||= CloudstackClient::Client.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key]
        )
        @client.debug = true if options[:debug]
        @client
      end

      def load_configuration(config_file = options[:config_file], env = options[:env])
        unless File.exists?(config_file)
          say "Configuration file #{config_file} not found.", :red
          say "Please run \'cs environment add\' to create one."
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
          say "Please check with 'cloudstack-cli environment list' and set a valid default environment."
          exit 1
        end
        config
      end

      def filter_by(objects, key, value)
        objects.select {|r| r[key.to_s].downcase == value.downcase}
      end

      def parse_file(file, extensions = %w(.json .yaml .yml))
        handler = case File.extname(file)
        when ".json"
          Object.const_get "JSON"
        when ".yaml", ".yml"
          Object.const_get "YAML"
        else
          say "File extension #{File.extname(file)} not supported. Supported extensions are #{extensions.join(', ')}", :red
          exit
        end
        begin
          return handler.load open(file){|f| f.read}
        rescue SystemCallError
          say "Can't find the file #{file}.", :red
          exit 1
        rescue => e
          say "Error parsing #{File.extname(file)} file:", :red
          say e.message
          exit 1
        end
      end
    end
  end
end
