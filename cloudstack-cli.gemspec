# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack-cli/version'

Gem::Specification.new do |gem|
  gem.name          = 'cloudstack-cli'
  gem.version       = CloudstackCli::VERSION
  gem.authors       = ['Nik Wolfgramm']
  gem.email         = %w(nik.wolfgramm@gmail.com)
  gem.description   = %q{cloudstack-cli is a CloudStack API command line client written in Ruby.}
  gem.summary       = %q{cloudstack-cli CloudStack API client}
  gem.date          = Time.now.utc.strftime("%Y-%m-%d")
  gem.homepage      = 'http://github.com/niwo/cloudstack-cli'
  gem.license       = 'MIT'

  gem.required_ruby_version = '>= 1.9.3'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = %w(cloudstack-cli)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)
  gem.rdoc_options  = %w[--line-numbers --inline-source]

  gem.add_development_dependency('rake', '~> 13.0')
  gem.add_development_dependency('minitest', '~> 5.11')

  gem.add_dependency('cloudstack_client', '~> 1.5.10')
  gem.add_dependency('thor', '~> 1.1.0')
end
