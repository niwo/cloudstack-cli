class Job < CloudstackCli::Base

  desc 'list', 'list async jobs'
  def list
    jobs = client.list_async_jobs
    if jobs.size < 1
      say "No jobs found."
    else
      table = [%w(Command Created Status ID User-ID)]
      jobs.each do |job|
        table << [
          job['cmd'].split('.')[-1],
          job['created'],
          job['jobstatus'],
          job['jobid'],
          job['userid']
        ]
      end
      print_table table
    end
  end

  desc 'query ID', 'query async job'
  def query(id)
    job = client.query_async_job_result(jobid: id)
    table = job.map do |key, value|
      [ set_color("#{key}:", :yellow), "#{value}" ]
    end
    print_table table
  end

end
