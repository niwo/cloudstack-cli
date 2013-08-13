require "thor"
require "yaml"

module CloudstackCli  
  class Base < Thor
    include Thor::Actions
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
        @config ||= CloudstackClient::ConnectionHelper.load_configuration(options[:config])
        @client ||= CloudstackClient::Connection.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key],
          opts
        )
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
        objects.select {|r| r[tag_name].downcase == tag.downcase }
      end
    end
  end
end