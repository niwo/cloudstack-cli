class SshKeyPair < CloudstackCli::Base

  desc "ssh_key_pair list", 'list ssh key pairs'
  option :listall
  option :account
  option :project
  def list
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

  desc 'ssh_key_pair create NAME', 'create ssh key pair'
  option :account
  option :project
  option :public_key
  def create(name)
    pair = client.create_ssh_key_pair(name, options)
    say "Name : #{pair['name']}"
    say "Fingerprint : #{pair['fingerprint']}"
    say "Privatekey:"
    say pair['privatekey']
  end

  desc 'ssh_key_pair delete NAME', 'delete ssh key pair'
  option :account
  option :project
  option :force, aliases: '-f', desc: "delete without asking"
  def delete(name)
    if options[:force] || yes?("Delete ssh key pair #{name}?", :yellow)
      if client.delete_ssh_key_pair(name, options)['success'] == "true"
        say("OK", :green)
      else
        say("Failed", :red)
        exit 1
      end
    end
  end
  
end