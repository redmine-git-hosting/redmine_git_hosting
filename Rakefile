require 'rake'
require 'rspec/core/rake_task'
require 'rdoc/task'


# Helper Functions
def name
  "Redmine Git Hosting"
end


def version
  line = File.read("init.rb")[/^\s*version\s*.*/]
  line.match(/.*version\s*['"](.*)['"]/)[1]
end


## RDoc Task
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{name} #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('app/**/*.rb')
end


## Other Tasks
desc "Show library version"
task :version do
  puts "#{name} #{version}"
end


desc "Start unit tests"
task :test => :default
task :default do
  RSpec::Core::RakeTask.new(:spec) do |config|
    config.rspec_opts = "--color --format nested --fail-fast"
  end
  Rake::Task["spec"].invoke
end


desc "Start unit tests in JUnit format"
task :test_junit do
  RSpec::Core::RakeTask.new(:spec) do |config|
    config.rspec_opts = "--format RspecJunitFormatter --out junit/rspec.xml"
  end
  Rake::Task["spec"].invoke
end
