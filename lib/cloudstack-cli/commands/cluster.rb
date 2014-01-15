class Cluster < CloudstackCli::Base

  desc 'list', 'list clusters'
  def list
    clusters = client.list_clusters(options)
    if clusters.size < 1
      say "No clusters found."
    else
      table = [["Name", "Pod-Name", "Type", "Zone"]]
      clusters.each do |cluster|
        table << [
        	cluster['name'], cluster['podname'],
          cluster['hypervisortype'], cluster['zonename']
        ]
      end
      print_table table
      say "Total number of clusters: #{clusters.size}"
    end
  end

end