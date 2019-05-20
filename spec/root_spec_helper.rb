unless ENV['DISABLE_COVERAGE'] == 'true'
  require 'simplecov'

  ## Start Simplecov
  SimpleCov.start 'rails' do
    add_group 'Redmine Git Hosting', 'plugins/redmine_git_hosting'
  end
end

## Load Redmine App
ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')
require 'rspec/rails'

## Load FactoryBots factories
Dir[Rails.root.join('plugins/*/spec/factories/**/*.rb')].each { |f| require f }

Dir[Rails.root.join('plugins/*/spec/support/**/*.rb')].each { |f| require f }

## Configure RSpec
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.infer_spec_type_from_file_location!

  config.color = true
  config.fail_fast = false

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

# Disable Test::Unit automatic runner
Test::Unit::AutoRunner.need_auto_run = false if defined?(Test::Unit::AutoRunner)
