class Snapshot < CloudstackCli::Base

  desc 'snapshot list', 'list snapshots'
  option :account
  option :project
  option :domain
  option :listall
  def list
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
    end
  end

end