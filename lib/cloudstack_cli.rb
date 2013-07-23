require 'yaml'
require 'rainbow'
require "thor"
require 'command_line_reporter'

require "cloudstack-cli/version"

# require subcommands
Dir[File.dirname(__FILE__) + '/../lib/cloudstack-cli/commands/*.rb'].each do |file| 
  require file
end

require "cloudstack-cli/helper"
require "cloudstack-cli/cli"