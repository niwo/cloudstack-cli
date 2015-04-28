module CloudstackCli
  class Cli < CloudstackCli::Base
    include Thor::Actions

    package_name "cloudstack-cli"

    class_option :config_file,
      default: File.join(Dir.home, '.cloudstack-cli.yml'),
      aliases: '-c',
      desc: 'Location of your cloudstack-cli configuration file'

    class_option :env,
      aliases: '-e',
      desc: 'Environment to use'

    class_option :debug,
      desc: 'Enable debug output',
      type: :boolean,
      default: false

    desc "version", "Print cloudstack-cli version number"
    def version
      say "cloudstack-cli version #{CloudstackCli::VERSION}"
      say " (cloudstack_client version #{CloudstackClient::VERSION})"
    end

    desc "setup", "Initial configuration of Cloudstack connection settings"
    def setup(env = options[:environment])
      invoke "environment:add", [env],
        :config_file => options[:config_file]
    end

    desc "completion", "Load the shell scripts for <tab> auto-completion"
    option :shell, default: 'bash'
    def completion
      shell_script = File.join(
        File.dirname(__FILE__), '..', '..',
        'completions', "cs.#{options[:shell]}"
      )
      unless File.file? shell_script
        say "Specified cloudstack-cli shell auto-completion rules for #{options[:shell]} not found.", :red
        exit 1
      end
      puts File.read shell_script
    end

    desc "command COMMAND [arg1=val1 arg2=val2...]", "Run a custom api command"
    option :format, default: 'json',
      enum: %w(json yaml), desc: "output format"
    option :pretty_print, default: true, type: :boolean,
      desc: "pretty print json output"
    def command(command, *args)
      params = {'command' => command}
      args.each do |arg|
        arg = arg.split('=')
        params[arg[0]] = arg[1]
      end
      data = client.send_request(params)
      output = if options[:format] == 'json'
        options[:pretty_print] ? JSON.pretty_generate(data) : data.to_json
      else
        data.to_yaml
      end
      puts output
    end

    # Require and describe subcommands
    Dir[File.dirname(__FILE__) + '/commands/*.rb'].each do |command_path|
      require command_path
      command = File.basename(command_path, ".rb")

      desc "#{command} SUBCOMMAND ...ARGS",
        "#{command.split('_').collect(&:capitalize).join(' ')} commands"
      subcommand command.to_sym,
        Object.const_get(command.split('_').collect(&:capitalize).join)
    end

    # Additional command maps (aliases)
    map %w(-v --version) => :version
    map 'env' => :environment
    map 'vm' => :virtual_machine
    map 'server' => :virtual_machine
  end
end
