require "bundler/gem_tasks"
require "rake/testtask"


Rake::TestTask.new do |t|
  t.libs << "spec"
  t.pattern = "spec/**/*_spec.rb"
  t.warning = false
end

task default: :test
