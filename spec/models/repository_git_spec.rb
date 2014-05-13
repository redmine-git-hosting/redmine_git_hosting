require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Repository::Git do

  before do
    @repository_git = FactoryGirl.create(:repository_git)
  end

  subject { @repository_git }

  it { should respond_to(:extra) }
  it { should respond_to(:url) }
  it { should respond_to(:root_url) }

  it { should be_valid }

  it { expect(@repository_git.is_default).to be true }

  it { expect(@repository_git.extra[:git_http]).to eq 1 }
  it { expect(@repository_git.extra[:git_daemon]).to be false }
  it { expect(@repository_git.extra[:git_notify]).to be false }
  it { expect(@repository_git.extra[:default_branch]).to eq "master" }


  describe "when git_daemon is true" do
    before { @repository_git.extra[:git_daemon] = true }
    it { should be_valid }
    it { expect(@repository_git.extra[:git_daemon]).to be true }
  end

  describe "when git_notify is true" do
    before { @repository_git.extra[:git_notify] = true }
    it { should be_valid }
    it { expect(@repository_git.extra[:git_notify]).to be true }
  end

  describe "when default_branch is changed" do
    before { @repository_git.extra[:default_branch] = 'devel' }
    it { should be_valid }
    it { expect(@repository_git.extra[:default_branch]).to eq 'devel' }
  end

end
