class SshKeyPair < CloudstackCli::Base

  desc "list", 'list ssh key pairs'
  option :listall, default: true
  option :account
  option :project
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_account
    resolve_project
    pairs = client.list_ssh_key_pairs(options)
    if pairs.size < 1
      say "No ssh key pairs found."
    else
      case options[:format].to_sym
      when :yaml
        puts({ssh_key_pairs: pairs}.to_yaml)
      when :json
        puts JSON.pretty_generate(ssh_key_pairs: pairs)
      else
        table = [["Name", "Fingerprint"]]
        pairs.each do |pair|
          table << [pair['name'], pair['fingerprint']]
        end
        print_table table
      end
    end
  end

  desc 'create NAME', 'create ssh key pair'
  option :account
  option :project
  def create(name)
    resolve_account
    resolve_project
    options[:name] = name
    pair = client.create_ssh_key_pair(options)
    say "Name : #{pair['name']}"
    say "Fingerprint : #{pair['fingerprint']}"
    say "Privatekey:"
    say pair['privatekey']
  end

  desc 'register NAME', 'register ssh key pair'
  option :account
  option :project
  option :public_key, required: true, desc: "path to public_key file"
  def register(name)
    resolve_account
    resolve_project
    options[:name] = name
    if File.exist?(options[:public_key])
      public_key = IO.read(options[:public_key])
    else
      say("Can't open public key #{options[:public_key]}", :red)
      exit 1
    end
    pair = client.register_ssh_key_pair(options)
    say "Name : #{pair['name']}"
    say "Fingerprint : #{pair['fingerprint']}"
    say "Privatekey:"
    say pair['privatekey']
  rescue => e
    say "Failed to register key: #{e.message}", :red
    exit 1
  end

  desc 'delete NAME', 'delete ssh key pair'
  option :account
  option :project
  option :force, aliases: '-f', desc: "delete without asking"
  def delete(name)
    resolve_account
    resolve_project
    options[:name] = name
    if options[:force] || yes?("Delete ssh key pair #{name}?", :yellow)
      if client.delete_ssh_key_pair(options)['success'] == "true"
        say("OK", :green)
      else
        say("Failed", :red)
        exit 1
      end
    end
  end

end
