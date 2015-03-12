class Project < CloudstackCli::Base

  desc "show NAME", "show detailed infos about a project"
  def show(name)
    unless project = client.get_project(name)
      puts "No project with name #{name} found."
    else
      table = project.map do |key, value|
        [ set_color("#{key}", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

  desc "list", "list projects"
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
      say "Total number of projects: #{projects.count}"
    end
  end

  desc "list_accounts PROJECT_NAME", "show accounts belonging to a project"
  def list_accounts(name)
    unless project = client.get_project(name)
      say "No project with name #{name} found."
    else
      accounts = client.list_project_accounts(project['id'], options)
      if accounts.size < 1
        say "No project accounts found."
      else
        table = [%w(Name Type Domain State)]
        accounts.each do |account|
          table << [
            account['name'],
            TYPES[account['accounttype']],
            account['domain'],
            account['state']
          ]
        end
        print_table table
        say "Total number of project accounts: #{accounts.size}"
        print_table table
      end
    end
  end

end
