module CloudstackCli  
  class Base < Thor
    include Thor::Actions
    attr_reader :config

    # catch control-c and exit
    trap("SIGINT") {
      puts
      puts "bye"
      exit!
    }

    no_commands do  
      def client
        @config ||= CloudstackClient::ConnectionHelper.load_configuration(options[:config])
        @client ||= CloudstackClient::Connection.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key]
        )
      end

      def find_project(project_name = options[:project])
        unless project = client.get_project(project_name)
          say "Project '#{options[:project]}' not found", :red
          exit 1
        end
        project
      end

      def filter_by(objects, tag_name, tag)
        objects.select {|r| r[tag_name].downcase == tag }
      end
    end
  end
end