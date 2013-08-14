class Job < CloudstackCli::Base

  desc 'list', 'list async jobs'
  def list
    jobs = client.list_jobs()
    if jobs.size < 1
      puts "No jobs found"
    else
      table = [["Command", "Created", "Status", "ID", "User ID"]]
      jobs.each do |job|
        table << [job['cmd'].split('.')[-1], job['created'], job['jobstatus'], job['jobid'], job['userid']]
      end
      print_table table
    end
  end

  desc 'query ID', 'query async job'
  def query(id)
    job = client.query_job(id)
    job.each do |key, value| 
      say "#{key} : "
      if value.is_a?(Hash)
        value.each {|subkey, subvalue| say "   #{subkey} : #{subvalue}"}
      else 
        say(value)
      end
    end
  end
  
end