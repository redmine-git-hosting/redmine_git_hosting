require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Repository::Xitolite do

  GIT_USER = 'git'

  before(:all) do
    Setting.plugin_redmine_git_hosting[:gitolite_redmine_storage_dir] = 'redmine/'
    Setting.plugin_redmine_git_hosting[:http_server_subdir] = 'git/'
    User.current = nil

    @project_parent = FactoryGirl.create(:project, identifier: 'project-parent')
    @project_child  = FactoryGirl.create(:project, identifier: 'project-child', parent_id: @project_parent.id, is_public: false)
  end


  def build_git_repository(opts = {})
    FactoryGirl.build(:repository_gitolite, opts)
  end


  def create_git_repository(opts = {})
    FactoryGirl.create(:repository_gitolite, opts)
  end


  describe 'common_tests : fast tests' do
    before(:each) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'

      @repository_1 = build_git_repository(project: @project_child, is_default: true)
      @repository_1.valid?
      @repository_1.build_extra(default_branch: 'master', key: RedmineGitHosting::Utils::Crypto.generate_secret(64))
    end

    subject { @repository_1 }

    it { should be_valid }

    ## Relations
    it { should have_many(:mirrors) }
    it { should have_many(:post_receive_urls) }
    it { should have_many(:deployment_credentials) }
    it { should have_many(:git_config_keys) }
    it { should have_many(:protected_branches) }

    it { should have_one(:extra) }

    ## Attributes
    it { expect(@repository_1.report_last_commit).to be true }
    it { expect(@repository_1.extra_report_last_commit).to be true }
    it { expect(@repository_1.git_default_branch).to eq 'master' }
    it { expect(@repository_1.gitolite_hook_key).to match /\A[a-zA-Z0-9]+\z/ }
    it { expect(@repository_1.git_daemon_enabled?).to be true }
    it { expect(@repository_1.git_annex_enabled?).to be false }
    it { expect(@repository_1.git_notification_enabled?).to be true }
    it { expect(@repository_1.smart_http_enabled?).to be true }
    it { expect(@repository_1.https_access_enabled?).to be true }
    it { expect(@repository_1.http_access_enabled?).to be false }
    it { expect(@repository_1.only_https_access_enabled?).to be true }
    it { expect(@repository_1.only_http_access_enabled?).to be false }
    it { expect(@repository_1.protected_branches_enabled?).to be false }
    it { expect(@repository_1.public_project?).to be false }
    it { expect(@repository_1.public_repo?).to be false }
    it { expect(@repository_1.urls_order).to eq [] }


    it 'should not allow identifier gitolite-admin' do
      expect(build_git_repository(project: @project_parent, identifier: 'gitolite-admin')).to be_invalid
    end


    describe '#exists_in_gitolite?' do
      it 'should check if repository exists on Gitolite side' do
        expect(RedmineGitHosting::Commands).to receive(:sudo_dir_exists?).with('repositories/redmine/project-parent/project-child.git')
        @repository_1.exists_in_gitolite?
      end
    end

    describe '#empty_in_gitolite?' do
      it 'should check if repository is empty on Gitolite side' do
        expect(RedmineGitHosting::Commands).to receive(:sudo_repository_empty?).with('repositories/redmine/project-parent/project-child.git')
        @repository_1.empty_in_gitolite?
      end
    end

    describe '#git_objects_count' do
      it 'should return repository objects count' do
        expect(RedmineGitHosting::Commands).to receive(:sudo_git_objects_count).with('repositories/redmine/project-parent/project-child.git')
        @repository_1.git_objects_count
      end
    end

    describe '#data_for_destruction' do
      it 'should return a hash of data' do
        expect(@repository_1.data_for_destruction).to eq({
          delete_repository: true,
          git_cache_id:      'project-child',
          repo_name:         'redmine/project-parent/project-child',
          repo_path:         '/home/git/repositories/redmine/project-parent/project-child.git',
        })
      end
    end

    describe '#empty?' do
      it 'should check if repository is empty from Redmine point of view' do
        expect(@repository_1.empty?).to be true
      end
    end

    describe '#empty_cache!' do
      it 'should flush the repository git cache' do
        expect(RedmineGitHosting::Cache).to receive(:clear_cache_for_repository).with('project-child')
        @repository_1.empty_cache!
      end
    end

    describe '#available_urls' do
      context 'with no option' do
        my_hash = {}

        it 'should return an empty Hash' do
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 0
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context 'with all options' do
        my_hash = {
          ssh:   { url: "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git",     committer: 'true' },
          https: { url: 'https://redmine-test-user@localhost/git/project-parent/project-child.git', committer: 'true' },
          http:  { url: 'http://redmine-test-user@localhost/git/project-parent/project-child.git',  committer: 'false' },
          go:    { url: 'localhost/go/project-parent/project-child',                                committer: 'false' },
          git:   { url: 'git://localhost/redmine/project-parent/project-child.git',                 committer: 'false' }
        }

        it 'should return a Hash of Git url' do
          @user = create_user_with_permissions(@project_child, login: 'redmine-test-user')
          User.current = @user
          @project_child.is_public = true
          @repository_1.extra[:git_daemon] = true
          @repository_1.extra[:git_http]   = 2
          @repository_1.extra.save
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context 'with git daemon' do
        my_hash = { git: { url: 'git://localhost/redmine/project-parent/project-child.git', committer: 'false' } }

        it 'should return a Hash of Git url' do
          User.current = nil
          @project_child.is_public = true
          @repository_1.extra[:git_daemon] = true
          @repository_1.extra[:git_http]   = 0
          @repository_1.extra.save
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context 'with ssh' do
        my_hash = { ssh: { url: "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git", committer: 'true' } }

        it 'should return a Hash of Git url' do
          @user = create_user_with_permissions(@project_child, login: 'redmine-test-user')
          User.current = @user
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 0
          @repository_1.extra.save
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context 'with http' do
        my_hash = { http: { url: 'http://localhost/git/project-parent/project-child.git', committer: 'false' } }

        it 'should return a Hash of Git url' do
          User.current = nil
          @project_child.is_public = false
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 3
          @repository_1.extra.save
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context 'with https' do
        my_hash = { https: { url: 'https://localhost/git/project-parent/project-child.git', committer: 'false' } }

        it 'should return a Hash of Git url' do
          User.current = nil
          @project_child.is_public = false
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 1
          @repository_1.extra.save
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context 'with http and https' do
        my_hash = {
          https: { url: 'https://localhost/git/project-parent/project-child.git', committer: 'false' },
          http:  { url: 'http://localhost/git/project-parent/project-child.git',  committer: 'false' }
        }

        it 'should return a Hash of Git url' do
          User.current = nil
          @project_child.is_public = false
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 2
          @repository_1.extra.save
          expect(@repository_1.available_urls).to eq my_hash
        end
      end
    end


    describe 'Repository::Xitolite class' do
      it { expect(Repository::Xitolite).to respond_to(:repo_ident_unique?) }
      it { expect(Repository::Xitolite).to respond_to(:have_duplicated_identifier?) }
      it { expect(Repository::Xitolite).to respond_to(:repo_path_to_git_cache_id) }
      it { expect(Repository::Xitolite).to respond_to(:find_by_path) }
    end
  end


  describe 'common_tests : long tests' do
    before do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'

      @repository_1 = create_git_repository(project: @project_child, is_default: true)
      extra = @repository_1.build_extra(default_branch: 'master', key: RedmineGitHosting::Utils::Crypto.generate_secret(64))
      extra.save!

      @repository_2 = create_git_repository(project: @project_child, identifier: 'repo-test')
    end

   context 'when blank identifier' do
      it 'should not allow identifier changes' do
        @repository_1.identifier = 'new_repo'
        expect(@repository_1).to be_invalid
        expect(@repository_1.identifier).to eq 'new_repo'
      end
    end

    context 'when non blank identifier' do
      it 'should not allow identifier changes' do
        @repository_2.identifier = 'new_repo2'
        expect(@repository_2).to be_valid
        expect(@repository_2.identifier).to eq 'repo-test'
      end
    end


    describe 'Test uniqueness' do
      context 'when blank identifier is already taken by a repository' do
        it { expect(build_git_repository(project: @project_child, identifier: '')).to be_invalid }
      end

      context 'when set as default and blank identifier is already taken by a repository' do
        it { expect(build_git_repository(project: @project_child, identifier: '', is_default: true)).to be_invalid }
      end

      context 'when identifier is already taken by a project' do
        it { expect(build_git_repository(project: @project_child, identifier: 'project-child')).to be_invalid }
      end

      context 'when identifier is already taken by a repository with same project' do
        it { expect(build_git_repository(project: @project_child, identifier: 'repo-test')).to be_invalid }
      end

      context 'when identifier are not unique' do
        it { expect(build_git_repository(project: @project_parent, identifier: 'repo-test')).to be_valid }
      end

      context 'when identifier are unique' do
        it 'should refuse duplicated identifier' do
          Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
          expect(build_git_repository(project: @project_parent, identifier: 'repo-test')).to be_invalid
        end
      end
    end
  end


  ##################################
  #                                #
  #  NON-UNIQUE REPOSITORIES TESTS #
  #                                #
  ##################################


  def build_collection_of_non_unique_repositories
    @repository_1 = build_git_repository(project: @project_child, is_default: true)
    @repository_1.valid?
    @repository_2 = build_git_repository(project: @project_child, identifier: 'repo-test')
    @repository_2.valid?

    @repository_3 = build_git_repository(project: @project_parent, is_default: true)
    @repository_3.valid?
    @repository_4 = build_git_repository(project: @project_parent, identifier: 'repo-test')
    @repository_4.valid?
  end


  def create_collection_of_non_unique_repositories
    @repository_1 = create_git_repository(project: @project_child, is_default: true)
    @repository_2 = create_git_repository(project: @project_child, identifier: 'repo-test')

    @repository_3 = create_git_repository(project: @project_parent, is_default: true)
    @repository_4 = create_git_repository(project: @project_parent, identifier: 'repo-test')
  end


  context 'when hierarchical_organisation with non_unique_identifier: fast tests' do
    before(:all) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'
      build_collection_of_non_unique_repositories
    end

    describe 'repository1' do
      it 'should be default repository' do
        expect(@repository_1.is_default).to be true
      end

      it 'should have nil identifier' do
        expect(@repository_1.identifier).to eq ''
      end

      it 'should have a valid url' do
        expect(@repository_1.url).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_1.root_url).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_1.git_cache_id).to eq 'project-child'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_1.redmine_name).to eq 'project-child'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_1.gitolite_repository_path).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_1.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/project-parent/project-child.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_1.gitolite_repository_name).to eq 'redmine/project-parent/project-child'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_1.redmine_repository_path).to eq 'project-parent/project-child'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_1.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_1.git_url).to eq 'git://localhost/redmine/project-parent/project-child.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_1.http_url).to eq 'http://localhost/git/project-parent/project-child.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_1.https_url).to eq 'https://localhost/git/project-parent/project-child.git'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_1.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_1.git_access_path).to eq 'redmine/project-parent/project-child.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_1.http_access_path).to eq 'git/project-parent/project-child.git'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_1.new_repository_name).to eq 'redmine/project-parent/project-child'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_1.old_repository_name).to eq 'redmine/project-parent/project-child'
      end
    end


    describe 'repository2' do
      it 'should not be default repository' do
        expect(@repository_2.is_default).to be false
      end

      it 'should have a valid identifier' do
        expect(@repository_2.identifier).to eq 'repo-test'
      end

      it 'should have a valid url' do
        expect(@repository_2.url).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_2.root_url).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_2.git_cache_id).to eq 'project-child/repo-test'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_2.redmine_name).to eq 'repo-test'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_2.gitolite_repository_path).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_2.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_2.gitolite_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_2.redmine_repository_path).to eq 'project-parent/project-child/repo-test'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_2.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child/repo-test.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_2.git_url).to eq 'git://localhost/redmine/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_2.http_url).to eq 'http://localhost/git/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_2.https_url).to eq 'https://localhost/git/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_2.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_2.git_access_path).to eq 'redmine/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_2.http_access_path).to eq 'git/project-parent/project-child/repo-test.git'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_2.new_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_2.old_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end
    end


    describe 'repository3' do
      it 'should be default repository' do
        expect(@repository_3.is_default).to be true
      end

      it 'should have nil identifier' do
        expect(@repository_3.identifier).to eq ''
      end

      it 'should have a valid url' do
        expect(@repository_3.url).to eq 'repositories/redmine/project-parent.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_3.root_url).to eq 'repositories/redmine/project-parent.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_3.git_cache_id).to eq 'project-parent'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_3.redmine_name).to eq 'project-parent'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_3.gitolite_repository_path).to eq 'repositories/redmine/project-parent.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_3.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/project-parent.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_3.gitolite_repository_name).to eq 'redmine/project-parent'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_3.redmine_repository_path).to eq 'project-parent'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_3.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_3.git_url).to eq 'git://localhost/redmine/project-parent.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_3.http_url).to eq 'http://localhost/git/project-parent.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_3.https_url).to eq 'https://localhost/git/project-parent.git'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_3.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_3.git_access_path).to eq 'redmine/project-parent.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_3.http_access_path).to eq 'git/project-parent.git'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_3.new_repository_name).to eq 'redmine/project-parent'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_3.old_repository_name).to eq 'redmine/project-parent'
      end
    end


    describe 'repository4' do
      it 'should not be default repository' do
        expect(@repository_4.is_default).to be false
      end

      it 'should have a valid identifier' do
        expect(@repository_4.identifier).to eq 'repo-test'
      end

      it 'should have a valid url' do
        expect(@repository_4.url).to eq 'repositories/redmine/project-parent/repo-test.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_4.root_url).to eq 'repositories/redmine/project-parent/repo-test.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_4.git_cache_id).to eq 'project-parent/repo-test'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_4.redmine_name).to eq 'repo-test'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_4.gitolite_repository_path).to eq 'repositories/redmine/project-parent/repo-test.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_4.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/project-parent/repo-test.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_4.gitolite_repository_name).to eq 'redmine/project-parent/repo-test'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_4.redmine_repository_path).to eq 'project-parent/repo-test'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_4.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent/repo-test.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_4.git_url).to eq 'git://localhost/redmine/project-parent/repo-test.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_4.http_url).to eq 'http://localhost/git/project-parent/repo-test.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_4.https_url).to eq 'https://localhost/git/project-parent/repo-test.git'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_4.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_4.git_access_path).to eq 'redmine/project-parent/repo-test.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_4.http_access_path).to eq 'git/project-parent/repo-test.git'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_4.new_repository_name).to eq 'redmine/project-parent/repo-test'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_4.old_repository_name).to eq 'redmine/project-parent/repo-test'
      end
    end
  end


  context 'when hierarchical_organisation with non_unique_identifier: long tests' do
    describe '.repo_ident_unique?' do
      it 'should be false' do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'
        expect(Repository::Xitolite.repo_ident_unique?).to be false
      end
    end

    describe '.have_duplicated_identifier?' do
      it 'should be true' do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'
        create_collection_of_non_unique_repositories
        expect(Repository::Xitolite.have_duplicated_identifier?).to be true
      end
    end

    describe '.repo_path_to_git_cache_id' do
      before do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'
        create_collection_of_non_unique_repositories
      end

      let(:repo1) { Repository::Xitolite.find_by_path(@repository_1.url, loose: true) }
      let(:repo2) { Repository::Xitolite.find_by_path(@repository_2.url, loose: true) }
      let(:repo3) { Repository::Xitolite.find_by_path(@repository_3.url, loose: true) }
      let(:repo4) { Repository::Xitolite.find_by_path(@repository_4.url, loose: true) }

      let(:git_cache_id1) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_1.url) }
      let(:git_cache_id2) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_2.url) }
      let(:git_cache_id3) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_3.url) }
      let(:git_cache_id4) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_4.url) }

      describe 'repositories should match' do
        it { expect(repo1).to eq @repository_1 }
        it { expect(repo2).to eq @repository_2 }
        it { expect(repo3).to eq @repository_3 }
        it { expect(repo4).to eq @repository_4 }

        it { expect(git_cache_id1).to eq 'project-child' }
        it { expect(git_cache_id2).to eq 'project-child/repo-test' }
        it { expect(git_cache_id3).to eq 'project-parent' }
        it { expect(git_cache_id4).to eq 'project-parent/repo-test' }
      end
    end
  end


  ##############################
  #                            #
  #  UNIQUE REPOSITORIES TESTS #
  #                            #
  ##############################


  def build_collection_of_unique_repositories
    @repository_1 = build_git_repository(project: @project_child, is_default: true)
    @repository_1.valid?
    @repository_2 = build_git_repository(project: @project_child, identifier: 'repo1-test')
    @repository_2.valid?

    @repository_3 = build_git_repository(project: @project_parent, is_default: true)
    @repository_3.valid?
    @repository_4 = build_git_repository(project: @project_parent, identifier: 'repo2-test')
    @repository_4.valid?
  end


  def create_collection_of_unique_repositories
    @repository_1 = create_git_repository(project: @project_child, is_default: true)
    @repository_2 = create_git_repository(project: @project_child, identifier: 'repo1-test')

    @repository_3 = create_git_repository(project: @project_parent, is_default: true)
    @repository_4 = create_git_repository(project: @project_parent, identifier: 'repo2-test')
  end


  context 'when flat_organisation with unique_identifier: fast tests' do
    before(:all) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'false'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
      build_collection_of_unique_repositories
    end


    describe 'repository1' do
      it 'should be default repository' do
        expect(@repository_1.is_default).to be true
      end

      it 'should have nil identifier' do
        expect(@repository_1.identifier).to eq ''
      end

      it 'should have a valid url' do
        expect(@repository_1.url).to eq 'repositories/redmine/project-child.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_1.root_url).to eq 'repositories/redmine/project-child.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_1.git_cache_id).to eq 'project-child'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_1.redmine_name).to eq 'project-child'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_1.gitolite_repository_path).to eq 'repositories/redmine/project-child.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_1.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/project-child.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_1.gitolite_repository_name).to eq 'redmine/project-child'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_1.redmine_repository_path).to eq  'project-child'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_1.new_repository_name).to eq 'redmine/project-child'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_1.old_repository_name).to eq 'redmine/project-child'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_1.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_1.git_access_path).to eq 'redmine/project-child.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_1.http_access_path).to eq 'git/project-child.git'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_1.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-child.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_1.git_url).to eq 'git://localhost/redmine/project-child.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_1.http_url).to eq 'http://localhost/git/project-child.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_1.https_url).to eq 'https://localhost/git/project-child.git'
      end
    end


    describe 'repository2' do
      it 'should not be default repository' do
        expect(@repository_2.is_default).to be false
      end

      it 'should have a valid identifier' do
        expect(@repository_2.identifier).to eq 'repo1-test'
      end

      it 'should have a valid url' do
        expect(@repository_2.url).to eq 'repositories/redmine/repo1-test.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_2.root_url).to eq 'repositories/redmine/repo1-test.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_2.git_cache_id).to eq 'repo1-test'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_2.redmine_name).to eq 'repo1-test'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_2.gitolite_repository_path).to eq 'repositories/redmine/repo1-test.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_2.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/repo1-test.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_2.gitolite_repository_name).to eq 'redmine/repo1-test'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_2.redmine_repository_path).to eq  'repo1-test'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_2.new_repository_name).to eq 'redmine/repo1-test'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_2.old_repository_name).to eq 'redmine/repo1-test'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_2.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_2.git_access_path).to eq 'redmine/repo1-test.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_2.http_access_path).to eq 'git/repo1-test.git'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_2.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/repo1-test.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_2.git_url).to eq 'git://localhost/redmine/repo1-test.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_2.http_url).to eq 'http://localhost/git/repo1-test.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_2.https_url).to eq 'https://localhost/git/repo1-test.git'
      end
    end


    describe 'repository3' do
      it 'should not be default repository' do
        expect(@repository_3.is_default).to be true
      end

      it 'should have nil identifier' do
        expect(@repository_3.identifier).to eq ''
      end

      it 'should have a valid url' do
        expect(@repository_3.url).to eq 'repositories/redmine/project-parent.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_3.root_url).to eq 'repositories/redmine/project-parent.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_3.git_cache_id).to eq 'project-parent'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_3.redmine_name).to eq 'project-parent'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_3.gitolite_repository_path).to eq 'repositories/redmine/project-parent.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_3.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/project-parent.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_3.gitolite_repository_name).to eq 'redmine/project-parent'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_3.redmine_repository_path).to eq  'project-parent'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_3.new_repository_name).to eq 'redmine/project-parent'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_3.old_repository_name).to eq 'redmine/project-parent'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_3.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_3.git_access_path).to eq 'redmine/project-parent.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_3.http_access_path).to eq 'git/project-parent.git'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_3.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/project-parent.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_3.git_url).to eq 'git://localhost/redmine/project-parent.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_3.http_url).to eq 'http://localhost/git/project-parent.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_3.https_url).to eq 'https://localhost/git/project-parent.git'
      end
    end


    describe 'repository4' do
      it 'should not be default repository' do
        expect(@repository_4.is_default).to be false
      end

      it 'should have a valid identifier' do
        expect(@repository_4.identifier).to eq 'repo2-test'
      end

      it 'should have a valid url' do
        expect(@repository_4.url).to eq 'repositories/redmine/repo2-test.git'
      end

      it 'should have a valid root_url' do
        expect(@repository_4.root_url).to eq 'repositories/redmine/repo2-test.git'
      end

      it 'should have a valid git_cache_id' do
        expect(@repository_4.git_cache_id).to eq 'repo2-test'
      end

      it 'should have a valid redmine_name' do
        expect(@repository_4.redmine_name).to eq 'repo2-test'
      end

      it 'should have a valid gitolite_repository_path' do
        expect(@repository_4.gitolite_repository_path).to eq 'repositories/redmine/repo2-test.git'
      end

      it 'should have a valid gitolite_full_repository_path' do
        expect(@repository_4.gitolite_full_repository_path).to eq '/home/git/repositories/redmine/repo2-test.git'
      end

      it 'should have a valid gitolite_repository_name' do
        expect(@repository_4.gitolite_repository_name).to eq 'redmine/repo2-test'
      end

      it 'should have a valid redmine_repository_path' do
        expect(@repository_4.redmine_repository_path).to eq  'repo2-test'
      end

      it 'should have a valid new_repository_name' do
        expect(@repository_4.new_repository_name).to eq 'redmine/repo2-test'
      end

      it 'should have a valid old_repository_name' do
        expect(@repository_4.old_repository_name).to eq 'redmine/repo2-test'
      end

      it 'should have a valid http_user_login' do
        expect(@repository_4.http_user_login).to eq ''
      end

      it 'should have a valid git_access_path' do
        expect(@repository_4.git_access_path).to eq 'redmine/repo2-test.git'
      end

      it 'should have a valid http_access_path' do
        expect(@repository_4.http_access_path).to eq 'git/repo2-test.git'
      end

      it 'should have a valid ssh_url' do
        expect(@repository_4.ssh_url).to eq "ssh://#{GIT_USER}@localhost/redmine/repo2-test.git"
      end

      it 'should have a valid git_url' do
        expect(@repository_4.git_url).to eq 'git://localhost/redmine/repo2-test.git'
      end

      it 'should have a valid http_url' do
        expect(@repository_4.http_url).to eq 'http://localhost/git/repo2-test.git'
      end

      it 'should have a valid https_url' do
        expect(@repository_4.https_url).to eq 'https://localhost/git/repo2-test.git'
      end
    end
  end


  context 'when flat_organisation with unique_identifier: long tests' do
    describe '.repo_ident_unique?' do
      it 'should be false' do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'false'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
        expect(Repository::Xitolite.repo_ident_unique?).to be true
      end
    end

    describe '.have_duplicated_identifier?' do
      it 'should be true' do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'false'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
        create_collection_of_unique_repositories
        expect(Repository::Xitolite.have_duplicated_identifier?).to be false
      end
    end

    describe '.repo_path_to_git_cache_id' do
      before do
        Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'false'
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'true'
        create_collection_of_unique_repositories
      end

      let(:repo1) { Repository::Xitolite.find_by_path(@repository_1.url, loose: true) }
      let(:repo2) { Repository::Xitolite.find_by_path(@repository_2.url, loose: true) }
      let(:repo3) { Repository::Xitolite.find_by_path(@repository_3.url, loose: true) }
      let(:repo4) { Repository::Xitolite.find_by_path(@repository_4.url, loose: true) }

      let(:git_cache_id1) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_1.url) }
      let(:git_cache_id2) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_2.url) }
      let(:git_cache_id3) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_3.url) }
      let(:git_cache_id4) { Repository::Xitolite.repo_path_to_git_cache_id(@repository_4.url) }

      describe 'repositories should match' do
        it { expect(repo1).to eq @repository_1 }
        it { expect(repo2).to eq @repository_2 }
        it { expect(repo3).to eq @repository_3 }
        it { expect(repo4).to eq @repository_4 }

        it { expect(git_cache_id1).to eq 'project-child' }
        it { expect(git_cache_id2).to eq 'repo1-test' }
        it { expect(git_cache_id3).to eq 'project-parent' }
        it { expect(git_cache_id4).to eq 'repo2-test' }
      end
    end
  end

end
