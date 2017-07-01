require "thor"
require "cloudstack-cli/thor_patch"
require "json"
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

      def load_configuration
        CloudstackClient::Configuration.load(options)
      rescue CloudstackClient::ConfigurationError => e
        say "Error: ", :red
        say e.message
        exit 1
      end

      def filter_by(objects, key, value)
        if objects.size == 0
          return objects
        elsif !(keys = objects.map{|i| i.keys}.flatten.uniq).include?(key)
          say "WARNING: Filter invalid, no key \"#{key}\" found.", :yellow
          say("DEBUG: Supported keys are, #{keys.join(', ')}.", :magenta) if options[:debug]
          return objects
        end
        objects.select do |object|
          object[key.to_s].to_s =~ /#{value}/i
        end
      rescue RegexpError => e
        say "ERROR: ", :red
        say "Invalid regular expression in filter - #{e.message}"
        exit 1
      end

      def filter_objects(objects, filter = options[:filter])
        filter.each do |key, value|
          objects = filter_by(objects, key, value)
          return objects if objects.size == 0
        end
        objects
      end

      def add_filters_to_options(command)
        options[:filter].each do |filter_key, filter_value|
          if client.api.params(command).find {|param| param["name"] == filter_key.downcase }
            options[filter_key.downcase] = filter_value.gsub(/[^\w\s\.-]/, '')
            options[:filter].delete(filter_key)
          end
        end
      end

      def parse_file(file, extensions = %w(.json .yaml .yml))
        handler = case File.extname(file)
        when ".json"
          Object.const_get "JSON"
        when ".yaml", ".yml"
          Object.const_get "YAML"
        else
          say "ERROR: ", :red
          say "File extension #{File.extname(file)} not supported. Supported extensions are #{extensions.join(', ')}"
          exit
        end
        begin
          return handler.load open(file){|f| f.read}
        rescue SystemCallError
          say "ERROR: ", :red
          say "Can't find the file '#{file}'."
          exit 1
        rescue => e
          say "ERROR: ", :red
          say "Can't parse file '#{file}': #{e.message}"
          exit 1
        end
      end
    end

  end # class
end # module
