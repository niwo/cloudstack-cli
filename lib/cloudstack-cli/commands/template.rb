class Template < CloudstackCli::Base

  desc 'list', 'list templates'
  option :project
  option :zone
  option :type,
    enum: %w(featured self self-executable executable community all),
    default: "featured"
  def list(type='featured')
    resolve_project
    resolve_zone
    options[:template_filter] = options[:type]
    options.delete(:filter)
    templates = client.list_templates(options)
    if templates.size < 1
      puts "No templates found."
    else
      table = [%w(Name Zone Format)]
      templates.each do |template|
        table <<  [template['name'], template['zonename'], template['format']]
      end
      print_table(table)
      say "Total number of templates: #{templates.size}"
    end
  end

end
