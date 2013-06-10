class Template < Thor

  desc 'list', 'list templates by type [featured|self|self-executable|executable|community]' 
  option :project
  def list(type='featured')
    cs_cli = CloudstackCli::Cli.new
    
    if options[:project]
      project = cs_cli.projects.select { |p| p['name'] == options[:project] }.first
      exit_now! "Project '#{options[:project]}' not found" unless project
    end
    
    exit_now! "unsupported template type '#{type}'" unless
      %w(featured self self-executable executable community).include? type
    templates = cs_cli.templates(type, project ? project['id'] : nil)
    if templates.size < 1
      puts "No templates found"
    else
      templates.each do |template|
        puts template['name']
      end
    end
  end

end