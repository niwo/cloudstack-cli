class Project < CloudstackCli::Base

  desc "project show NAME", "show detailed infos about a project"
  option :project
  def show(name)
    unless project = client.get_project(name)
      puts "No project with name #{name} found."
    else
      project.each do |key, value|
        say "#{key}: ", :yellow
        say "#{value}"
      end
    end
  end

  desc "project list", "list projects"
  def list
    projects = client.list_projects
    if projects.size < 1
      puts "No projects found."
    else
      table = [["Name", "Displaytext", "Domain"]]
      projects.each do |project|
        table << [project['name'], project['displaytext'], project['domain']]
      end
      print_table(table)
    end
  end
  
end