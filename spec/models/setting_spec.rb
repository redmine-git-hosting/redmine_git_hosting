require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Setting do
  before do
    RedmineGitHosting::Config.reload_from_file!
    @settings = Setting.plugin_redmine_git_hosting
    @default_settings = Redmine::Plugin.find('redmine_git_hosting').settings[:default]
  end

  subject { @settings }

  it { should be_an_instance_of(Hash) }

  # it { expect(@settings).to eq @default_settings }
end
