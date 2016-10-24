require "cloudstack-cli"

require "minitest/spec"
require "minitest/autorun"
require "minitest/pride"

# make the config file setup awailable to all specs
CONFIG = "--config-file=#{File.expand_path('cloudstack-cli.yml', File.dirname(__FILE__))}"
