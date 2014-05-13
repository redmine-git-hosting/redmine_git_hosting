require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Repository do

  before do
    @project      = FactoryGirl.create(:project, :identifier => 'project-test')
    @repository_1 = FactoryGirl.create(:repository, :project_id => @project.id, :is_default => true)
    @repository_2 = FactoryGirl.create(:repository, :project_id => @project.id, :identifier => 'repo-test')
  end

  subject { @repository_1 }

  it { should respond_to(:extra) }
  it { should respond_to(:url) }
  it { should respond_to(:root_url) }

  it { should respond_to(:git_cache_id) }
  it { should respond_to(:redmine_name) }

  it { should respond_to(:gitolite_repository_path) }
  it { should respond_to(:gitolite_repository_name) }
  it { should respond_to(:redmine_repository_path) }
  it { should respond_to(:new_repository_name) }
  it { should respond_to(:old_repository_name) }
  it { should respond_to(:http_user_login) }
  it { should respond_to(:git_access_path) }
  it { should respond_to(:http_access_path) }
  it { should respond_to(:ssh_url) }
  it { should respond_to(:git_url) }
  it { should respond_to(:http_url) }
  it { should respond_to(:https_url) }
  it { should respond_to(:available_urls) }
  it { should respond_to(:mailing_list_default_users) }
  it { should respond_to(:mailing_list_effective) }
  it { should respond_to(:mailing_list_params) }
  it { should respond_to(:get_full_parent_path) }
  it { should respond_to(:exists_in_gitolite?) }
  it { should respond_to(:gitolite_hook_key) }

  it { should be_valid }

  it { expect(@repository_1.is_default).to be true }

  it { expect(@repository_1.extra[:git_http]).to eq 1 }
  it { expect(@repository_1.extra[:git_daemon]).to be false }
  it { expect(@repository_1.extra[:git_notify]).to be true }
  it { expect(@repository_1.extra[:default_branch]).to eq "master" }

  it { expect(@repository_1.git_cache_id).to eq "project-test" }
  it { expect(@repository_1.redmine_name).to eq "project-test" }

  it { expect(@repository_2.git_cache_id).to eq "project-test/repo-test" }
  it { expect(@repository_2.redmine_name).to eq "repo-test" }


  describe "when git_daemon is true" do
    before { @repository_1.extra[:git_daemon] = true }
    it { should be_valid }
    it { expect(@repository_1.extra[:git_daemon]).to be true }
  end

  describe "when git_notify is true" do
    before { @repository_1.extra[:git_notify] = true }
    it { should be_valid }
    it { expect(@repository_1.extra[:git_notify]).to be true }
  end

  describe "when default_branch is changed" do
    before { @repository_1.extra[:default_branch] = 'devel' }
    it { should be_valid }
    it { expect(@repository_1.extra[:default_branch]).to eq 'devel' }
  end

end
