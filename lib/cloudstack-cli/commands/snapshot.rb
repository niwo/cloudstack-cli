class Snapshot < CloudstackCli::Base

  desc 'list', 'list snapshots'
  option :account
  option :project
  option :domain
  option :listall, default: true
  def list
    resolve_account
    resolve_project
    resolve_domain
    snapshots = client.list_snapshots(options)
    if snapshots.size < 1
      say "No snapshots found."
    else
      table = [["Account", "Name", "Volume", "Created", "Type"]]
      snapshots.each do |snapshot|
        table << [
        	snapshot['account'], snapshot['name'], snapshot['volumename'],
        	snapshot['created'], snapshot['snapshottype']
        ]
      end
      print_table table
      say "Total number of snapshots: #{snapshots.size}"
    end
  end

end
