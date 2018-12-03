class Template < CloudstackCli::Base

  desc 'list', 'list templates'
  option :project
  option :zone
  option :type,
    enum: %w(featured self self-executable executable community all),
    default: "featured"
  option :format, default: "table",
    enum: %w(table json yaml)
  def list(type='featured')
    resolve_project
    resolve_zone
    options[:template_filter] = options[:type]
    templates = client.list_templates(options)
    if templates.size < 1
      puts "No templates found."
    else
      case options[:format].to_sym
      when :yaml
        puts({templates: templates}.to_yaml)
      when :json
        puts JSON.pretty_generate(templates: templates)
      else
        table = [%w(Name Created Zone Featured Public Format)]
        templates.each do |template|
          table << [
            template['name'],
            (Time.parse(template['created']).strftime("%F") rescue "-"),
            template['zonename'],
            template['isfeatured'],
            template['ispublic'],
            template['format']
          ]
        end
        print_table(table)
        say "Total number of templates: #{templates.size}"
      end
    end
  end

end
