require 'database_cleaner'
require 'factory_girl_rails'
require 'rubygems'
require 'simplecov'
require 'simplecov-rcov'

## Load FactoryGirls factories
Dir[Rails.root.join("plugins/redmine_git_hosting/spec/factories/**/*.rb")].each {|f| require f}

## Configure SimpleCov
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
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
