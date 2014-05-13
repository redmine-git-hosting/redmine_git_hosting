require 'database_cleaner'
require 'factory_girl_rails'
require 'rake'
require 'rubygems'
require 'simplecov'
require 'simplecov-rcov'

## Load FactoryGirls factories
Dir[Rails.root.join("plugins/redmine_git_hosting/spec/factories/**/*.rb")].each {|f| require f}

## Load RakeTasks
Dir[Rails.root.join("plugins/redmine_git_hosting/lib/tasks/**/*.rake")].each {|f| load f}
Rake::Task.define_task(:environment)

## Configure SimpleCov
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter,
]

SimpleCov.start 'rails'

## Configure RSpec
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.color = true
  config.fail_fast = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Rake::Task['redmine_git_hosting:restore_defaults'].invoke
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
