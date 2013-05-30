$LOAD_PATH.unshift File.dirname(__FILE__)

require "cloudstack-bootstrap/version"
require "cloudstack-bootstrap/cloudstack_client"
require "cloudstack-bootstrap/connection_helper"
require "cloudstack-bootstrap/ssh_command"
require "cloudstack-bootstrap/cloudstack_cli"

require 'yaml'
require 'rainbow'