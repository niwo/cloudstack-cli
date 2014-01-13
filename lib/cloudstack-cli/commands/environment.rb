class Environment < CloudstackCli::Base

  desc "list", "list cloudstack-cli environments"
  def list
    config = parse_configfile(options[:config_file])
    table = [%w(Name URL)]
    table << ["default", config[:url]]
    config.each_key do |key|
      table << [key, config[key][:url]] unless key.class == Symbol
    end
    print_table table
  end

  desc "add", "add a new Cloudstack environment"
  option :url
  option :api_key
  option :secret_key
  def add(env = options[:environment])
    config = {}
    unless options[:url]
      say "Add a new environment (#{env || 'default'})."
      say "What's the URL of your Cloudstack API?", :yellow
      say "Example: https://my-cloudstack-service/client/api/", :green
      config[:url] = ask("URL:", :magenta)
    end
    unless options[:api_key]
      config[:api_key] = ask("API Key:", :magenta)
    end
    unless options[:secret_key]
      config[:secret_key] = ask("Secret Key:", :magenta)
    end
    if env
      config = {env => config}
    end
    if File.exists? options[:config_file]
      old_config = parse_configfile(options[:config_file])
      say "Warning: #{options[:config_file]} already exists.", :red
      exit unless yes?("Do you want to merge your settings? [y/N]", :red)
      config = old_config.merge(config)
    end
    File.open(options[:config_file], 'w+') {|f| f.write(config.to_yaml) }
    say "OK, config-file written to #{options[:config_file]}.", :green
  end

  desc "delete", "delete a Cloudstack connection"
  def delete(name)
    config = parse_configfile(options[:config_file])
    exit unless yes?("Do you really want delete environment #{name}? [y/N]", :red)
    config.delete(name)
    File.open(options[:config_file], 'w+') {|f| f.write(config.to_yaml) }
    say "OK.", :green
  end

  no_commands do

    def parse_configfile(file)
      if File.exists? file
        begin
          return YAML::load(IO.read(file))
        rescue
          say "Error loading configuration from file #{file}.", :red
          exit 1
        end
      else
        say "Can't load configuration from file #{file}.", :red
        exit 1
      end
    end

  end

end