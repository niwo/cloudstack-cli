class InfrastructureStack < CloudstackCli::Base

  desc "create STACKFILE", "create a infrastructure stack"
  def create(stackfile)
    puts stack = parse_file(stackfile)
    say "Create '#{stack["name"]}' infrastructure stack...", :green

    create_domains(stack['domains'])

    say "Finished.", :green
  end

  desc "destroy STACKFILE", "destroy a infrastructure stack"
  def destroy(stackfile)

  end

  no_commands do
    def create_domains(domains)
      domains.each do |domain|
        puts domain
      end
    end

  end

end
