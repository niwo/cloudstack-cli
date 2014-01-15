class Iso < CloudstackCli::Base

  desc 'list [TYPE]', "list iso's by type [featured|self|self-executable|executable|community], default is featured"
  option :project
  option :zone
  option :account
  option :listall
  def list(type='featured')
    project = find_project if options[:project]
    unless %w(featured self self-executable executable community).include?(type)
      say "unsupported iso type '#{type}'", :red
      exit 1
    end
    zone = client.get_zone(options[:zone]) if options[:zone]
    isos = client.list_isos(
      filter: type,
      project_id: project ? project['id'] : nil,
      zone_id: zone ? zone['id'] : nil
    )
    if isos.size < 1
      puts "No iso's found"
    else
      table = [["Name", "Zone", "Bootable"]]
      isos.each do |iso|
        table <<  [iso['name'], iso['zonename'], iso['bootable']]
      end
      print_table(table)
      say "Total number of isos: #{isos.size}"
    end
  end

end