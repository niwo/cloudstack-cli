class Environment < CloudstackCli::Base

  desc "list", "list cloudstack-cli environments"
    def environments(file = options[:config])
      config = {}
      if File.exists? file
        begin
          config = YAML::load(IO.read(file))
        rescue
          error "Can't load configuration from file #{config_file}."
          exit 1
        end
        table = [%w(Name URL)]
        table << ["default", config[:url]]
        config.each_key do |key|
          table << [key, config[key][:url]] unless key.class == Symbol
        end
        print_table table
      end
    end

end