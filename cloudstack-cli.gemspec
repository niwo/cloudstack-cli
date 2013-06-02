# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack-cli/version'

Gem::Specification.new do |gem|
  gem.name          = "cloudstack-cli"
  gem.version       = CloudstackCli::VERSION
  gem.authors       = ["niwo"]
  gem.email         = ["nik.wolfgramm@gmail.com"]
  gem.description   = %q{Cloudstack CLI gives command line access to the CloudStack API commands.}
  gem.summary       = %q{cloudstack-cli}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('rake', '~> 10.0.4')
  gem.add_dependency('thor', '~> 0.18.1')
  gem.add_dependency('net-ssh', '~> 2.6.7')
  gem.add_dependency('rainbow', '~> 1.1.4')
  gem.add_dependency('command_line_reporter', '~> 3.2.1')
end
