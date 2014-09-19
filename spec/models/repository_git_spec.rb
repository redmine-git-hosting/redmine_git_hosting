require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Repository::Git do

  GIT_USER = 'git'

  before(:all)  do
    Setting.plugin_redmine_git_hosting[:gitolite_redmine_storage_dir] = 'redmine/'
    Setting.plugin_redmine_git_hosting[:http_server_subdir] = 'git/'
    User.current = nil

    @project_parent = FactoryGirl.create(:project, :identifier => 'project-parent')
    @project_child  = FactoryGirl.create(:project, :identifier => 'project-child', :parent_id => @project_parent.id)
  end


  def build_git_repository(opts = {})
    FactoryGirl.build(:repository_git, opts)
  end


  def create_git_repository(opts = {})
    FactoryGirl.create(:repository_git, opts)
  end


  def create_user_with_permissions(project)
    role = FactoryGirl.create(:role)
    user = FactoryGirl.create(:user, :login => 'redmine-test-user')

    members = Member.new(:role_ids => [role.id], :user_id => user.id)
    project.members << members

    return user
  end


  describe "common_tests" do
    before(:each) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'

      @repository_1 = create_git_repository(:project => @project_child, :is_default => true)
      @repository_2 = create_git_repository(:project => @project_child, :identifier => 'repo-test')
    end

    subject { @repository_1 }

    ## Relations
    it { should have_many(:mirrors) }
    it { should have_many(:post_receive_urls) }
    it { should have_many(:deployment_credentials) }
    it { should have_many(:git_config_keys) }
    it { should have_many(:protected_branches) }

    it { should have_one(:git_extra) }
    it { should have_one(:git_notification) }

    it { should be_valid }

    ## Attributes
    it { should respond_to(:identifier) }
    it { should respond_to(:url) }
    it { should respond_to(:root_url) }

    ## Methods
    it { should respond_to(:extra) }

    it { should respond_to(:report_last_commit_with_git_hosting) }
    it { should respond_to(:extra_report_last_commit_with_git_hosting) }

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

    it { should respond_to(:default_list) }
    it { should respond_to(:mail_mapping) }

    it { should respond_to(:get_full_parent_path) }
    it { should respond_to(:exists_in_gitolite?) }
    it { should respond_to(:gitolite_hook_key) }

    ## Test attributes more specifically
    it { expect(@repository_1.report_last_commit_with_git_hosting).to be true }
    it { expect(@repository_1.extra_report_last_commit_with_git_hosting).to be true }

    it { expect(@repository_1.extra[:git_http]).to eq 1 }
    it { expect(@repository_1.extra[:git_daemon]).to be false }
    it { expect(@repository_1.extra[:git_notify]).to be false }
    it { expect(@repository_1.extra[:default_branch]).to eq 'master' }

    it { expect(@repository_1.available_urls).to be_a(Hash) }


    describe "invalid cases" do
      it "should not allow identifier gitolite-admin" do
        expect(build_git_repository(:project => @project_parent, :identifier => 'gitolite-admin')).to be_invalid
      end

      context "when blank identifier" do
        before do
          @repository_1.identifier = 'gitolite-admin'
        end
        it "should not allow identifier changes" do
          expect(@repository_1).to be_invalid
          expect(@repository_1.identifier).to eq 'gitolite-admin'
        end
      end

      context "when non blank identifier" do
        before do
          @repository_2.identifier = 'gitolite-admin'
        end
        it "should not allow identifier changes" do
          expect(@repository_2).to be_valid
          expect(@repository_2.identifier).to eq 'repo-test'
        end
      end
    end


    describe "Test uniqueness" do
      context "when blank identifier is already taken by a repository" do
        it { expect(build_git_repository(:project => @project_child, :identifier => '')).to be_invalid }
      end

      context "when set as default and blank identifier is already taken by a repository" do
        it { expect(build_git_repository(:project => @project_child, :identifier => '', :is_default => true)).to be_invalid }
      end

      context "when identifier is already taken by a project" do
        it { expect(build_git_repository(:project => @project_child, :identifier => 'project-child')).to be_invalid }
      end

      context "when identifier is already taken by a repository with same project" do
        it { expect(build_git_repository(:project => @project_child, :identifier => 'repo-test')).to be_invalid }
      end

      context "when identifier are not unique" do
        it { expect(build_git_repository(:project => @project_parent, :identifier => 'repo-test')).to be_valid }
      end

      context "when identifier are unique" do
        before do
          Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
        end

        it { expect(build_git_repository(:project => @project_parent, :identifier => 'repo-test')).to be_invalid }
      end
    end


    describe "#available_urls" do
      context "with no option" do
        before do
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 0
          @repository_1.save
        end

        my_hash = {}

        it "should return an empty Hash" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with all options" do
        before do
          @user = create_user_with_permissions(@project_child)
          User.current = @user

          @repository_1.extra[:git_daemon] = true
          @repository_1.extra[:git_http]   = 2
          @repository_1.save
        end

        my_hash = {
          :ssh   => {:url => "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git",             :commiter => "false"},
          :https => {:url => "https://redmine-test-user@localhost/git/project-parent/project-child.git", :commiter => "false"},
          :http  => {:url => "http://redmine-test-user@localhost/git/project-parent/project-child.git",  :commiter => "false"},
          :git   => {:url => "git://localhost/redmine/project-parent/project-child.git",                 :commiter => "false"}
        }

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with git daemon" do
        before do
          User.current = nil

          @repository_1.extra[:git_daemon] = true
          @repository_1.extra[:git_http]   = 0
          @repository_1.save
        end

        my_hash = {:git => {:url=>"git://localhost/redmine/project-parent/project-child.git", :commiter=>"false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with ssh" do
        before do
          @user = create_user_with_permissions(@project_child)
          User.current = @user

          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 0
          @repository_1.save
        end

        my_hash = { :ssh => {:url => "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git", :commiter => "false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with http" do
        before do
          User.current = nil
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 3
          @repository_1.save
        end

        my_hash = { :http => {:url => "http://localhost/git/project-parent/project-child.git", :commiter => "false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with https" do
        before do
          User.current = nil
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 1
          @repository_1.save
        end

        my_hash = { :https => {:url => "https://localhost/git/project-parent/project-child.git", :commiter => "false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with http and https" do
        before do
          User.current = nil
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 2
          @repository_1.save
        end

        my_hash = {
          :https => {:url => "https://localhost/git/project-parent/project-child.git", :commiter => "false"},
          :http  => {:url => "http://localhost/git/project-parent/project-child.git",  :commiter => "false"}
        }

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end
    end

    describe "Repository::Git class" do
      it { expect(Repository::Git).to respond_to(:repo_ident_unique?) }
      it { expect(Repository::Git).to respond_to(:have_duplicated_identifier?) }
      it { expect(Repository::Git).to respond_to(:repo_path_to_git_cache_id) }
      it { expect(Repository::Git).to respond_to(:find_by_path) }

      describe ".repo_ident_unique?" do
        it { expect(Repository::Git.repo_ident_unique?).to be false }
      end

      describe ".have_duplicated_identifier?" do
        it { expect(Repository::Git.have_duplicated_identifier?).to be false }
      end

      describe ".repo_path_to_git_cache_id" do
        describe "when repo path is not found" do
          before do
            @git_cache_id = Repository::Git.repo_path_to_git_cache_id('foo.git')
          end

          it { expect(@git_cache_id).to be nil }
        end
      end
    end
  end


  def collection_of_unique_repositories
    @repository_1 = create_git_repository(:project => @project_child, :is_default => true)
    @repository_2 = create_git_repository(:project => @project_child, :identifier => 'repo1-test')

    @repository_3 = create_git_repository(:project => @project_parent, :is_default => true)
    @repository_4 = create_git_repository(:project => @project_parent, :identifier => 'repo2-test')
  end


  def collection_of_non_unique_repositories
    @repository_1 = create_git_repository(:project => @project_child, :is_default => true)
    @repository_2 = create_git_repository(:project => @project_child, :identifier => 'repo-test')

    @repository_3 = create_git_repository(:project => @project_parent, :is_default => true)
    @repository_4 = create_git_repository(:project => @project_parent, :identifier => 'repo-test')
  end


  context "when hierarchical_organisation with non_unique_identifier" do
    before(:each) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'
      collection_of_non_unique_repositories
    end

    describe ".repo_ident_unique?" do
      it "should be false" do
        expect(Repository::Git.repo_ident_unique?).to be false
      end
    end

    describe ".have_duplicated_identifier?" do
      it "should be true" do
        expect(Repository::Git.have_duplicated_identifier?).to be true
      end
    end


    describe "repository1" do
      it "should be default repository" do
        expect(@repository_1.is_default).to be true
      end

      it "should have nil identifier" do
        expect(@repository_1.identifier).to be nil
      end

      it "should have a valid url" do
        expect(@repository_1.url).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it "should have a valid root_url" do
        expect(@repository_1.root_url).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_1.git_cache_id).to eq 'project-child'
      end

      it "should have a valid redmine_name" do
        expect(@repository_1.redmine_name).to eq 'project-child'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_1.gitolite_repository_path).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_1.gitolite_repository_name).to eq 'redmine/project-parent/project-child'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_1.redmine_repository_path).to eq 'project-parent/project-child'
      end

      it "should have a valid ssh_url" do
        expect(@repository_1.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git"
      end

      it "should have a valid git_url" do
        expect(@repository_1.git_url).to eq 'git://localhost/redmine/project-parent/project-child.git'
      end

      it "should have a valid http_url" do
        expect(@repository_1.http_url).to eq 'http://localhost/git/project-parent/project-child.git'
      end

      it "should have a valid https_url" do
        expect(@repository_1.https_url).to eq 'https://localhost/git/project-parent/project-child.git'
      end

      it "should have a valid http_user_login" do
        expect(@repository_1.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_1.git_access_path).to eq 'redmine/project-parent/project-child.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_1.http_access_path).to eq 'git/project-parent/project-child.git'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_1.new_repository_name).to eq 'redmine/project-parent/project-child'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_1.old_repository_name).to eq 'redmine/project-parent/project-child'
      end
    end


    describe "repository2" do
      it "should not be default repository" do
        expect(@repository_2.is_default).to be false
      end

      it "should have a valid identifier" do
        expect(@repository_2.identifier).to eq 'repo-test'
      end

      it "should have a valid url" do
        expect(@repository_2.url).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid root_url" do
        expect(@repository_2.root_url).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_2.git_cache_id).to eq 'project-child/repo-test'
      end

      it "should have a valid redmine_name" do
        expect(@repository_2.redmine_name).to eq 'repo-test'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_2.gitolite_repository_path).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_2.gitolite_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_2.redmine_repository_path).to eq 'project-parent/project-child/repo-test'
      end

      it "should have a valid ssh_url" do
        expect(@repository_2.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child/repo-test.git"
      end

      it "should have a valid git_url" do
        expect(@repository_2.git_url).to eq 'git://localhost/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid http_url" do
        expect(@repository_2.http_url).to eq 'http://localhost/git/project-parent/project-child/repo-test.git'
      end

      it "should have a valid https_url" do
        expect(@repository_2.https_url).to eq 'https://localhost/git/project-parent/project-child/repo-test.git'
      end

      it "should have a valid http_user_login" do
        expect(@repository_2.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_2.git_access_path).to eq 'redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_2.http_access_path).to eq 'git/project-parent/project-child/repo-test.git'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_2.new_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_2.old_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end
    end


    describe "repository3" do
      it "should be default repository" do
        expect(@repository_3.is_default).to be true
      end

      it "should have nil identifier" do
        expect(@repository_3.identifier).to be nil
      end

      it "should have a valid url" do
        expect(@repository_3.url).to eq 'repositories/redmine/project-parent.git'
      end

      it "should have a valid root_url" do
        expect(@repository_3.root_url).to eq 'repositories/redmine/project-parent.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_3.git_cache_id).to eq 'project-parent'
      end

      it "should have a valid redmine_name" do
        expect(@repository_3.redmine_name).to eq 'project-parent'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_3.gitolite_repository_path).to eq 'repositories/redmine/project-parent.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_3.gitolite_repository_name).to eq 'redmine/project-parent'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_3.redmine_repository_path).to eq 'project-parent'
      end

      it "should have a valid ssh_url" do
        expect(@repository_3.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent.git"
      end

      it "should have a valid git_url" do
        expect(@repository_3.git_url).to eq 'git://localhost/redmine/project-parent.git'
      end

      it "should have a valid http_url" do
        expect(@repository_3.http_url).to eq 'http://localhost/git/project-parent.git'
      end

      it "should have a valid https_url" do
        expect(@repository_3.https_url).to eq 'https://localhost/git/project-parent.git'
      end

      it "should have a valid http_user_login" do
        expect(@repository_3.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_3.git_access_path).to eq 'redmine/project-parent.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_3.http_access_path).to eq 'git/project-parent.git'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_3.new_repository_name).to eq 'redmine/project-parent'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_3.old_repository_name).to eq 'redmine/project-parent'
      end
    end


    describe "repository4" do
      it "should not be default repository" do
        expect(@repository_4.is_default).to be false
      end

      it "should have a valid identifier" do
        expect(@repository_4.identifier).to eq 'repo-test'
      end

      it "should have a valid url" do
        expect(@repository_4.url).to eq 'repositories/redmine/project-parent/repo-test.git'
      end

      it "should have a valid root_url" do
        expect(@repository_4.root_url).to eq 'repositories/redmine/project-parent/repo-test.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_4.git_cache_id).to eq 'project-parent/repo-test'
      end

      it "should have a valid redmine_name" do
        expect(@repository_4.redmine_name).to eq 'repo-test'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_4.gitolite_repository_path).to eq 'repositories/redmine/project-parent/repo-test.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_4.gitolite_repository_name).to eq 'redmine/project-parent/repo-test'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_4.redmine_repository_path).to eq 'project-parent/repo-test'
      end

      it "should have a valid ssh_url" do
        expect(@repository_4.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent/repo-test.git"
      end

      it "should have a valid git_url" do
        expect(@repository_4.git_url).to eq 'git://localhost/redmine/project-parent/repo-test.git'
      end

      it "should have a valid http_url" do
        expect(@repository_4.http_url).to eq 'http://localhost/git/project-parent/repo-test.git'
      end

      it "should have a valid https_url" do
        expect(@repository_4.https_url).to eq 'https://localhost/git/project-parent/repo-test.git'
      end

      it "should have a valid http_user_login" do
        expect(@repository_4.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_4.git_access_path).to eq 'redmine/project-parent/repo-test.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_4.http_access_path).to eq 'git/project-parent/repo-test.git'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_4.new_repository_name).to eq 'redmine/project-parent/repo-test'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_4.old_repository_name).to eq 'redmine/project-parent/repo-test'
      end
    end


    describe ".repo_path_to_git_cache_id" do
      before do
        @repo1 = Repository::Git.repo_path_to_object(@repository_1.url)
        @repo2 = Repository::Git.repo_path_to_object(@repository_2.url)
        @repo3 = Repository::Git.repo_path_to_object(@repository_3.url)
        @repo4 = Repository::Git.repo_path_to_object(@repository_4.url)

        @git_cache_id1 = Repository::Git.repo_path_to_git_cache_id(@repository_1.url)
        @git_cache_id2 = Repository::Git.repo_path_to_git_cache_id(@repository_2.url)
        @git_cache_id3 = Repository::Git.repo_path_to_git_cache_id(@repository_3.url)
        @git_cache_id4 = Repository::Git.repo_path_to_git_cache_id(@repository_4.url)
      end

      describe "repositories should match" do
        it { expect(@repo1).to eq @repository_1 }
        it { expect(@repo2).to eq @repository_2 }
        it { expect(@repo3).to eq @repository_3 }
        it { expect(@repo4).to eq @repository_4 }

        it { expect(@git_cache_id1).to eq 'project-child' }
        it { expect(@git_cache_id2).to eq 'project-child/repo-test' }
        it { expect(@git_cache_id3).to eq 'project-parent' }
        it { expect(@git_cache_id4).to eq 'project-parent/repo-test' }
      end
    end
  end


  context "when flat_organisation with unique_identifier" do
    before(:each) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'false'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
      collection_of_unique_repositories
    end

    describe ".repo_ident_unique?" do
      it "should be false" do
        expect(Repository::Git.repo_ident_unique?).to be true
      end
    end

    describe ".have_duplicated_identifier?" do
      it "should be true" do
        expect(Repository::Git.have_duplicated_identifier?).to be false
      end
    end


    describe "repository1" do
      it "should be default repository" do
        expect(@repository_1.is_default).to be true
      end

      it "should have nil identifier" do
        expect(@repository_1.identifier).to be nil
      end

      it "should have a valid url" do
        expect(@repository_1.url).to eq 'repositories/redmine/project-child.git'
      end

      it "should have a valid root_url" do
        expect(@repository_1.root_url).to eq 'repositories/redmine/project-child.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_1.git_cache_id).to eq 'project-child'
      end

      it "should have a valid redmine_name" do
        expect(@repository_1.redmine_name).to eq 'project-child'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_1.gitolite_repository_path).to eq 'repositories/redmine/project-child.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_1.gitolite_repository_name).to eq 'redmine/project-child'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_1.redmine_repository_path).to eq  'project-child'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_1.new_repository_name).to eq 'redmine/project-child'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_1.old_repository_name).to eq 'redmine/project-child'
      end

      it "should have a valid http_user_login" do
        expect(@repository_1.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_1.git_access_path).to eq 'redmine/project-child.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_1.http_access_path).to eq 'git/project-child.git'
      end

      it "should have a valid ssh_url" do
        expect(@repository_1.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-child.git"
      end

      it "should have a valid git_url" do
        expect(@repository_1.git_url).to eq 'git://localhost/redmine/project-child.git'
      end

      it "should have a valid http_url" do
        expect(@repository_1.http_url).to eq 'http://localhost/git/project-child.git'
      end

      it "should have a valid https_url" do
        expect(@repository_1.https_url).to eq 'https://localhost/git/project-child.git'
      end
    end


    describe "repository2" do
      it "should not be default repository" do
        expect(@repository_2.is_default).to be false
      end

      it "should have a valid identifier" do
        expect(@repository_2.identifier).to eq 'repo1-test'
      end

      it "should have a valid url" do
        expect(@repository_2.url).to eq 'repositories/redmine/repo1-test.git'
      end

      it "should have a valid root_url" do
        expect(@repository_2.root_url).to eq 'repositories/redmine/repo1-test.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_2.git_cache_id).to eq 'repo1-test'
      end

      it "should have a valid redmine_name" do
        expect(@repository_2.redmine_name).to eq 'repo1-test'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_2.gitolite_repository_path).to eq 'repositories/redmine/repo1-test.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_2.gitolite_repository_name).to eq 'redmine/repo1-test'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_2.redmine_repository_path).to eq  'repo1-test'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_2.new_repository_name).to eq 'redmine/repo1-test'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_2.old_repository_name).to eq 'redmine/repo1-test'
      end

      it "should have a valid http_user_login" do
        expect(@repository_2.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_2.git_access_path).to eq 'redmine/repo1-test.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_2.http_access_path).to eq 'git/repo1-test.git'
      end

      it "should have a valid ssh_url" do
        expect(@repository_2.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/repo1-test.git"
      end

      it "should have a valid git_url" do
        expect(@repository_2.git_url).to eq 'git://localhost/redmine/repo1-test.git'
      end

      it "should have a valid http_url" do
        expect(@repository_2.http_url).to eq 'http://localhost/git/repo1-test.git'
      end

      it "should have a valid https_url" do
        expect(@repository_2.https_url).to eq 'https://localhost/git/repo1-test.git'
      end
    end


    describe "repository3" do
      it "should not be default repository" do
        expect(@repository_3.is_default).to be true
      end

      it "should have nil identifier" do
        expect(@repository_3.identifier).to be nil
      end

      it "should have a valid url" do
        expect(@repository_3.url).to eq 'repositories/redmine/project-parent.git'
      end

      it "should have a valid root_url" do
        expect(@repository_3.root_url).to eq 'repositories/redmine/project-parent.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_3.git_cache_id).to eq 'project-parent'
      end

      it "should have a valid redmine_name" do
        expect(@repository_3.redmine_name).to eq 'project-parent'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_3.gitolite_repository_path).to eq 'repositories/redmine/project-parent.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_3.gitolite_repository_name).to eq 'redmine/project-parent'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_3.redmine_repository_path).to eq  'project-parent'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_3.new_repository_name).to eq 'redmine/project-parent'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_3.old_repository_name).to eq 'redmine/project-parent'
      end

      it "should have a valid http_user_login" do
        expect(@repository_3.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_3.git_access_path).to eq 'redmine/project-parent.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_3.http_access_path).to eq 'git/project-parent.git'
      end

      it "should have a valid ssh_url" do
        expect(@repository_3.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent.git"
      end

      it "should have a valid git_url" do
        expect(@repository_3.git_url).to eq 'git://localhost/redmine/project-parent.git'
      end

      it "should have a valid http_url" do
        expect(@repository_3.http_url).to eq 'http://localhost/git/project-parent.git'
      end

      it "should have a valid https_url" do
        expect(@repository_3.https_url).to eq 'https://localhost/git/project-parent.git'
      end
    end


    describe "repository4" do
      it "should not be default repository" do
        expect(@repository_4.is_default).to be false
      end

      it "should have a valid identifier" do
        expect(@repository_4.identifier).to eq 'repo2-test'
      end

      it "should have a valid url" do
        expect(@repository_4.url).to eq 'repositories/redmine/repo2-test.git'
      end

      it "should have a valid root_url" do
        expect(@repository_4.root_url).to eq 'repositories/redmine/repo2-test.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_4.git_cache_id).to eq 'repo2-test'
      end

      it "should have a valid redmine_name" do
        expect(@repository_4.redmine_name).to eq 'repo2-test'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_4.gitolite_repository_path).to eq 'repositories/redmine/repo2-test.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_4.gitolite_repository_name).to eq 'redmine/repo2-test'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_4.redmine_repository_path).to eq  'repo2-test'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_4.new_repository_name).to eq 'redmine/repo2-test'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_4.old_repository_name).to eq 'redmine/repo2-test'
      end

      it "should have a valid http_user_login" do
        expect(@repository_4.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_4.git_access_path).to eq 'redmine/repo2-test.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_4.http_access_path).to eq 'git/repo2-test.git'
      end

      it "should have a valid ssh_url" do
        expect(@repository_4.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/repo2-test.git"
      end

      it "should have a valid git_url" do
        expect(@repository_4.git_url).to eq 'git://localhost/redmine/repo2-test.git'
      end

      it "should have a valid http_url" do
        expect(@repository_4.http_url).to eq 'http://localhost/git/repo2-test.git'
      end

      it "should have a valid https_url" do
        expect(@repository_4.https_url).to eq 'https://localhost/git/repo2-test.git'
      end
    end


    describe ".repo_path_to_git_cache_id" do
      before do
        @repo1 = Repository::Git.repo_path_to_object(@repository_1.url)
        @repo2 = Repository::Git.repo_path_to_object(@repository_2.url)
        @repo3 = Repository::Git.repo_path_to_object(@repository_3.url)
        @repo4 = Repository::Git.repo_path_to_object(@repository_4.url)

        @git_cache_id1 = Repository::Git.repo_path_to_git_cache_id(@repository_1.url)
        @git_cache_id2 = Repository::Git.repo_path_to_git_cache_id(@repository_2.url)
        @git_cache_id3 = Repository::Git.repo_path_to_git_cache_id(@repository_3.url)
        @git_cache_id4 = Repository::Git.repo_path_to_git_cache_id(@repository_4.url)
      end

      describe "repositories should match" do
        it { expect(@repo1).to eq @repository_1 }
        it { expect(@repo2).to eq @repository_2 }
        it { expect(@repo3).to eq @repository_3 }
        it { expect(@repo4).to eq @repository_4 }

        it { expect(@git_cache_id1).to eq 'project-child' }
        it { expect(@git_cache_id2).to eq 'repo1-test' }
        it { expect(@git_cache_id3).to eq 'project-parent' }
        it { expect(@git_cache_id4).to eq 'repo2-test' }
      end
    end
  end


  describe "Gitolite specific tests" do
    describe "repo foo" do
      before do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'

        @foo = create_git_repository(:project => @project_child, :identifier => 'foo')
        RedmineGitolite::GitHosting.resync_gitolite(:add_repository, @foo.id, :create_readme_file => true)
        @foo.fetch_changesets
      end

      it "should create repositories" do
        expect(@foo.exists_in_gitolite?).to be true
        expect(@foo.empty?).to be false
      end
    end

    describe "repo bar" do
      before do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'

        @bar = create_git_repository(:project => @project_child, :identifier => 'bar')
        RedmineGitolite::GitHosting.resync_gitolite(:add_repository, @bar.id, :create_readme_file => false)
        @bar.fetch_changesets
      end

      it "should create repositories" do
        expect(@bar.exists_in_gitolite?).to be true
        expect(@bar.empty?).to be true
      end
    end

  end
end
