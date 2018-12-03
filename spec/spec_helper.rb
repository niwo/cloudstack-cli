require "cloudstack-cli"

require "minitest/spec"
require "minitest/autorun"
require "minitest/pride"

# make the config file setup available to all specs
ZONE = "Sandbox-simulator"
TEMPLATE = "CentOS 5.6 (64-bit) no GUI (Simulator)"
OFFERING_S = "Small Instance"
OFFERING_M = "Medium Instance"
