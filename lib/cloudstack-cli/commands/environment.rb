class Environment < CloudstackCli::Base

  desc "list", "list cloudstack-cli environments"
  def list
    config = parse_config_file
    table = [%w(Name URL Default)]
    table << ['-', config[:url], !config[:default]]
    config.each_key do |key|
      unless key.class == Symbol
        table << [key, config[key][:url], key == config[:default]]
      end
    end
    print_table table
  end

  desc "add", "add a new Cloudstack environment"
  option :url
  option :api_key
  option :secret_key
  option :default, type: :boolean
  def add(env = options[:environment])
    config = {}
    unless options[:url]
      say "Add a new environment...", :green
      say "Environment name: #{env}" if env
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
      config[:default] = env if options[:default]
    end
    
    if File.exists? options[:config_file]
      old_config = parse_config_file
      if !env || old_config.has_key?(env)
        say "This environment already exists!", :red
        exit unless yes?("Do you want to override your settings? [y/N]", :yellow)
      end
      config = old_config.merge(config)
    else
      newfile = true
      config[:default] = env if env
    end

    write_config_file(config)
    if newfile
      say "OK. Created configuration file at #{options[:config_file]}.", :green
    else
      say "Added environment #{env}", :green
    end
  end

  desc "delete", "delete a Cloudstack connection"
  def delete(env)
    config = parse_config_file
    if config.delete(env)
      exit unless yes?("Do you really want to delete environment #{env}? [y/N]", :yellow)
      config.delete :default if config[:default] == env
      write_config_file(config)
      say "OK.", :green
    else
      say "Environment #{env} does not exist.", :red
    end
  end

  desc "default ENV", "set the default environment"
  def default(env)
    config = parse_config_file
    if env == '-'
      config.delete :default
    else
      unless config.has_key?(env)
        say "Environment #{env} does not exist.", :red
        exit 1
      end
      config[:default] = env
    end
    write_config_file(config)
    say "Default environment set to #{env}."
  end

  no_commands do

    def parse_config_file
      if File.exists? options[:config_file]
        begin
          return YAML::load(IO.read(options[:config_file]))
        rescue
          say "Error loading configuration from file #{options[:config_file]}.", :red
          exit 1
        end
      else
        say "Can't load configuration from file #{options[:config_file]}.", :red
        exit 1
      end
    end

    def write_config_file(config)
      begin
        return File.open(options[:config_file], 'w+') {|f| f.write(config.to_yaml) }
      rescue
        say "Can't open configuration file #{options[:config_file]} for writing.", :red
        exit 1
      end
    end

  end

end