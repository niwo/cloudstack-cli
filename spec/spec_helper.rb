require "cloudstack-cli"

require "minitest/spec"
require "minitest/autorun"
require "minitest/pride"

# make the config file setup awailable to all specs
CONFIG = "--config-file=#{File.expand_path('cloudstack.yml', File.dirname(__FILE__))}"
ZONE = "Sandbox-simulator"
TEMPLATE = "CentOS 5.3(64-bit) no GUI (Simulator)"
OFFERING_S = "Small Instance"
OFFERING_M = "Medium Instance"
