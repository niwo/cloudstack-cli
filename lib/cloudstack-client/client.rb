require 'base64'
require 'openssl'
require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'json'
require 'yaml'

module CloudstackClient
  class Connection

    @@async_poll_interval = 2.0
    @@async_timeout = 400

    # include all commands
    Dir.glob(File.dirname(__FILE__) + "/commands/*.rb").each do |file| 
      require file
      module_name = File.basename(file, '.rb').split('_').map{|f| f.capitalize}.join
      include Object.const_get("CloudstackClient").const_get(module_name)
    end

    attr_accessor :verbose

    def initialize(api_url, api_key, secret_key, opts = {})
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @use_ssl = api_url.start_with? "https"
      @verbose = opts[:quiet] ? false : true
    end

    ##
    # Sends a synchronous request to the CloudStack API and returns the response as a Hash.
    #
    # The wrapper element of the response (e.g. mycommandresponse) is discarded and the
    # contents of that element are returned.

    def send_request(params)
      params['response'] = 'json'
      params['apiKey'] = @api_key

      params_arr = []
      params.sort.each { |elem|
        params_arr << elem[0].to_s + '=' + CGI.escape(elem[1].to_s).gsub('+', '%20').gsub(' ','%20')
      }
      data = params_arr.join('&')
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, data.downcase)
      signature = Base64.encode64(signature).chomp
      signature = CGI.escape(signature)

      url = "#{@api_url}?#{data}&signature=#{signature}"

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @use_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      begin
        response = http.request(Net::HTTP::Get.new(uri.request_uri))
      rescue
        puts "Error connecting to API:"
        puts "#{@api_url} is not reachable"
        exit 1
      end

      if !response.is_a?(Net::HTTPOK)
        puts "Error #{response.code}: #{response.message}"
        puts JSON.pretty_generate(JSON.parse(response.body))
        puts "URL: #{url}"
        exit 1
      end

      begin 
        json = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Error parsing response from server."
        exit 1
      end
      json[params['command'].downcase + 'response']
    end

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params)

      json = send_request(params)

      params = {
          'command' => 'queryAsyncJobResult',
          'jobId' => json['jobid']
      }

      max_tries = (@@async_timeout / @@async_poll_interval).round
      max_tries.times do
        json = send_request(params)
        status = json['jobstatus']

        print "." if @verbose

        if status == 1
          return json['jobresult']
        elsif status == 2
          puts
          puts "Request failed (#{json['jobresultcode']}): #{json['jobresult']}"
          exit 1
        end

        STDOUT.flush
        sleep @@async_poll_interval
      end

      print "\n"
      puts "Error: Asynchronous request timed out"
      exit 1
    end

  end # class
end