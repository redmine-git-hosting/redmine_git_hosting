require File.expand_path(File.dirname(__FILE__) + '/../../../spec/spec_helper')

## Configure RSpec
RSpec.configure do |config|

  # Include our helpers from support directory
  config.include GlobalHelpers

  config.before(:suite) do
    RedmineGitHosting::Config.reload_from_file!
    Setting.enabled_scm = ['Git', 'Subversion', 'Xitolite']
  end

end
