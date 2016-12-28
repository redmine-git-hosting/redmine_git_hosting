require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Project do

  before(:all) do
    @project    = create(:project)
    @git_repo_1 = create_git_repository(project: @project, is_default: true)
    @git_repo_2 = create_git_repository(project: @project, identifier: 'git-repo-test')
    @svn_repo_1 = create_svn_repository(project: @project, identifier: 'svn-repo-test', url: 'http://svn-repo-test')
  end

  subject { @project }

  ## Test relations
  it { should respond_to(:gitolite_repos) }
  it { should respond_to(:repo_blank_ident) }

  it 'should have 1 repository with blank ident' do
    expect(@project.repo_blank_ident).to eq @git_repo_1
  end

  it 'should have 2 Git repositories' do
    expect(@project.gitolite_repos).to include @git_repo_1, @git_repo_2
  end

  it 'should have 3 repositories' do
    expect(@project.repositories).to include @git_repo_1, @git_repo_2, @svn_repo_1
  end

  it 'should not match existing repository identifier' do
    expect(build(:project, identifier: 'git-repo-test')).to be_invalid
  end

  it 'should not match Gitolite Admin repository identifier' do
    expect(build(:project, identifier: 'gitolite-admin')).to be_invalid
  end

end
