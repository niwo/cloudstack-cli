class Stack < Thor

	desc "create STACKFILE", "create a stack of servers"
  def create(stackfile)
    CloudstackCli::Cli.new.bootstrap_server(
        name,
        options[:zone],
        options[:template],
        options[:offering],
        options[:networks],
        options[:port_forwarding],
        options[:project]
      )
  end

end