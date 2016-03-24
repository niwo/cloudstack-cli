class SshKeyPair < CloudstackCli::Base

  desc "list", 'list ssh key pairs'
  option :listall, default: true
  option :account, desc: "name of the account"
  option :project, desc: "name of the project"
  def list
    resolve_account
    resolve_project
    pairs = client.list_ssh_key_pairs(options)
    if pairs.size < 1
      say "No ssh key pairs found."
    else
      table = [["Name", "Fingerprint"]]
      pairs.each do |pair|
        table << [pair['name'], pair['fingerprint']]
      end
      print_table table
    end
  end

  desc 'create NAME', 'create ssh key pair'
  option :account, desc: "name of the account"
  option :project, desc: "name of the project"
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
  option :account, desc: "name of the account"
  option :project, desc: "name of the project"
  option :public_key, required: true, desc: "path to public_key file"
  def register(name)
    resolve_account
    resolve_project
    options[:name] = name
    if File.exist?(options[:public_key])
      public_key = IO.read(options[:public_key])
      options[:public_key] = public_key
    else
      say("Can't open public key #{options[:public_key]}", :red)
      exit 1
    end
    pair = client.register_ssh_key_pair(options)
    say "Name : #{pair['name']}"
    say "Fingerprint : #{pair['fingerprint']}"
    say "Privatekey : #{pair['privatekey']}"
  rescue => e
    say "Failed to register key: #{e.message}", :red
    exit 1
  end

  desc 'delete NAME', 'delete ssh key pair'
  option :account, desc: "name of the account"
  option :project, desc: "name of the project"
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

  desc 'reset_vm_keys', 'Resets the SSH Key for virtual machine. The virtual machine must be in a "Stopped" state.'
  option :keypair, desc: "name of keypair", required: true
  option :virtual_machine, desc: "name of virtual machine", required: true
  option :account, desc: "name of the account"
  option :project, desc: "name of the project"
  def reset_vm_keys
    resolve_account
    resolve_project

    unless virtual_machine = client.list_virtual_machines({name: options[:virtual_machine], list_all: true}.merge options).first
      puts "No virtual machine found."
    else
      unless virtual_machine['state'].downcase == "stopped"
        say "ERROR: Virtual machine must be in stopped state.", :red
        exit 1
      end
      unless options[:force] || yes?("Reset ssh key for VM #{options[:virtual_machine]}? (y/N)", :yellow)
        exit
      end
      client.reset_ssh_key_for_virtual_machine(options.merge(id: virtual_machine['id']))
      say "OK", :green
    end
  end

end
