class Project < CloudstackCli::Base

  desc "list", "list projects"
  def list
    projects = client.list_projects
    if projects.size < 1
      puts "No projects found"
    else
      table = [["Name", "Displaytext", "Domain"]]
      projects.each do |project|
        table << [project['name'], project['displaytext'], project['domain']]
      end
      print_table(table)
    end
  end
  
end