require 'yaml'
require "thor"

require "cloudstack-cli/version"
require "cloudstack-cli/helper"
require "cloudstack-cli/base"

# require subcommands
Dir[File.dirname(__FILE__) + '/../lib/cloudstack-cli/commands/*.rb'].each do |file| 
  require file
end
require "cloudstack-cli/cli"