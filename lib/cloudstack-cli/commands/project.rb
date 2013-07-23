class Project < Thor

  desc "project list", "list projects"
  def list
    cs_cli = CloudstackCli::Helper.new(options[:config])
    projects = cs_cli.projects
    if projects.size < 1
      puts "No projects found"
    else
      projects.each do |project|
        puts "#{project['name']} - #{project['displaytext']} - #{project['domain']}"
      end
    end
  end
end