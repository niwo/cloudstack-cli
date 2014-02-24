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
  gem.homepage      = 'http://niwo.github.io/cloudstack-cli/'
  gem.license       = 'MIT'

  gem.required_ruby_version = '>= 1.9.3'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = %w(cs)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)
  gem.rdoc_options  = %w[--line-numbers --inline-source]

  gem.add_development_dependency('rdoc', '~> 4.1')
  gem.add_development_dependency('rake', '~> 10.1')
  
  gem.add_dependency('thor', '~> 0.18')
  gem.add_dependency('cloudstack_client', '~> 0.4', '>= 0.4.4')
end
