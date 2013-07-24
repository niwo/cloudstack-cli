class Template < CloudstackCli::Base

  desc 'list', 'list templates by type [featured|self|self-executable|executable|community]' 
  option :project
  def list(type='featured')
    if options[:project]
      project = client.list_projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
    end
    
    unless %w(featured self self-executable executable community).include? type
      say "unsupported template type '#{type}'", :red
      exit 1
    end
    templates = client.list_templates(type, project ? project['id'] : nil)
    if templates.size < 1
      puts "No templates found"
    else
      table = [["Name", "Zone"]]
      templates.each do |template|
        table <<  [template['name'], template['zonename']]
      end
      print_table(table)
    end
  end

end