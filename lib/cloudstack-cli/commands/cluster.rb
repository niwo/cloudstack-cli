class Cluster < CloudstackCli::Base

  desc 'list', 'list clusters'
  option :zone, desc: "lists clusters by zone"
  def list
    resolve_zone if options[:zone]
    clusters = client.list_clusters(options)
    if clusters.size < 1
      say "No clusters found."
    else
      table = [%w(Name Pod_Name Type Zone State)]
      clusters.each do |cluster|
        table << [
        	cluster['name'], cluster['podname'],
          cluster['hypervisortype'], cluster['zonename'],
          cluster['managedstate']
        ]
      end
      print_table table
      say "Total number of clusters: #{clusters.size}"
    end
  end

end
