class Cluster < CloudstackCli::Base

  desc 'list', 'list clusters'
  option :zone, desc: "lists clusters by zone"
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_zone if options[:zone]
    clusters = client.list_clusters(options)
    if clusters.size < 1
      say "No clusters found."
    else
      case options[:format].to_sym
      when :yaml
        puts({clusters: clusters}.to_yaml)
      when :json
        puts JSON.pretty_generate(clusters: clusters)
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

end
