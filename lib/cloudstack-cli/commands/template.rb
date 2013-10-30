class Template < CloudstackCli::Base

  desc 'template list [TYPE]', 'list templates by type [featured|self|self-executable|executable|community], default is featured' 
  option :project
  option :zone
  def list(type='featured')
    project = find_project if options[:project]
    unless %w(featured self self-executable executable community).include? type
      say "unsupported template type '#{type}'", :red
      exit 1
    end
    zone = client.get_zone(options[:zone]) if options[:zone]
    templates = client.list_templates(
      filter: type,
      project_id: project ? project['id'] : nil,
      zone_id: zone ? zone['id'] : nil
    )
    if templates.size < 1
      puts "No templates found"
    else
      table = [["Name", "Zone", "Format"]]
      templates.each do |template|
        table <<  [template['name'], template['zonename'], template['format']]
      end
      print_table(table)
    end
  end

end