module CloudstackCli  
  class Base < Thor
    include Thor::Actions
    attr_reader :config
    no_commands do 
      def client
        @config ||= CloudstackClient::ConnectionHelper.load_configuration(options[:config])
        @client ||= CloudstackClient::Connection.new(
          @config[:url],
          @config[:api_key],
          @config[:secret_key]
        )
      end
    end
  end
end