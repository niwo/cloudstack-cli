class Snapshot < CloudstackCli::Base

  desc 'list', 'list snapshots'
  option :account, desc: "the account associated with the snapshot"
  option :project, desc: "the project associated with the snapshot"
  option :domain, desc: "the domain name of the snapshot's account"
  option :listall, default: true, desc: "list all resources the caller has rights on"
  option :state, desc: "filter snapshots by state"
  def list
    resolve_account
    resolve_project
    resolve_domain
    snapshots = client.list_snapshots(options)
    if snapshots.size < 1
      say "No snapshots found."
    else
      table = [%w(Account Name Volume Created Type State)]
      snapshots = filter_by(snapshots, :state, options[:state]) if options[:state]
      snapshots.each do |snapshot|
        table << [
        	snapshot['account'], snapshot['name'], snapshot['volumename'],
        	snapshot['created'], snapshot['snapshottype'], snapshot['state']
        ]
      end
      print_table table
      say "Total number of snapshots: #{snapshots.size}"
    end
  end

end
