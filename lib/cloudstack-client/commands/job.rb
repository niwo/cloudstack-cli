module CloudstackClient

	module Job

		##
    # Retrieves the current status of asynchronous job.

    def query_job(id)
      params = {
          'command' => 'queryAsyncJobResult',
          'jobid' => id,
      }
      send_request(params)
    end

    ##
    # Lists all pending asynchronous jobs for the account.

    def list_jobs(opts = {})
      params = {
          'command' => 'listAsyncJobs'
      }
      params['listall'] = true if opts[:listall]
      send_request(params)['asyncjobs']
    end

	end

end