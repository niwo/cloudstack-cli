class Infrastack < CloudstackCli::Base

  desc "create STACKFILE", "create a infrastructure stack"
  def create(stackfile)
    stack = parse_file(stackfile)
    say "Create stack #{stack["name"]}...", :green
    say "Finished.", :green
  end

  desc "destroy STACKFILE", "destroy a infrastructure stack"
  def destroy(stackfile)

  end

  no_commands do

  end

end
