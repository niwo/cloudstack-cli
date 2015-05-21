class InfrastructureStack < CloudstackCli::Base

  desc "create STACKFILE", "create a infrastructure stack"
  def create(stackfile)
    stack = parse_file(stackfile)
    say "Create '#{stack["name"]}' infrastructure stack...", :green

    Domain.new.create_domains(stack['domains'])

    say "Infrastructure stack '#{stack["name"]}' finished.", :green
  end

  desc "destroy STACKFILE", "destroy a infrastructure stack"
  def destroy(stackfile)
    stack = parse_file(stackfile)
    say "Destroy '#{stack["name"]}' infrastructure stack...", :green



    Domain.new.delete_domains(stack['domains'].reverse)
    say "Infrastructure stack '#{stack["name"]}' finished.", :green
  end



end
