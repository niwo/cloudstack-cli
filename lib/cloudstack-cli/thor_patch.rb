# Fixes thor help for subcommands
# https://github.com/erikhuda/thor/pull/330

class Thor
  class << self
    attr_accessor :parent_class

    def basename2(subcommand = false)
      bn  = parent_class && parent_class.basename2
      bn2 = basename
      ns  = self.namespace.split(':').last
      bn ? (subcommand ? bn : "#{bn} #{ns}") : bn2
    end

    def banner(command, namespace = nil, subcommand = false)
      "#{basename2(subcommand)} #{command.formatted_usage(self, $thor_runner, subcommand)}"
    end

    alias :old_subcommand :subcommand

    def subcommand(subcommand, subcommand_class)
      subcommand_class.parent_class = self
      old_subcommand(subcommand, subcommand_class)
    end
  end
end
