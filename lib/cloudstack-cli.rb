$LOAD_PATH.unshift File.dirname(__FILE__)

require 'yaml'
require 'rainbow'
require "thor"

require "cloudstack-cli/version"
require "cloudstack-cli/cloudstack_client"
require "cloudstack-cli/connection_helper"
require "cloudstack-cli/ssh_command"

# require subcommands
Dir[File.dirname(__FILE__) + '/../lib/cloudstack-cli/commands/*.rb'].each do |file| 
  require file
end

require "cloudstack-cli/cloudstack_cli"

