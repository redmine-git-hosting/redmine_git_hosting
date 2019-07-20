require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Repository::Xitolite do

  GIT_USER = 'git'

  before(:all) do
    Setting.plugin_redmine_git_hosting[:gitolite_redmine_storage_dir] = 'redmine/'
    Setting.plugin_redmine_git_hosting[:http_server_subdir] = 'git/'
    User.current = nil

    @project_parent = FactoryBot.create(:project, identifier: 'project-parent')
    @project_child  = FactoryBot.create(:project, identifier: 'project-child', parent_id: @project_parent.id, is_public: false)
  end


  describe 'common_tests : fast tests' do
    before(:each) do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = 'true'
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = 'false'

      @repository_1 = build_git_repository(project: @project_child, is_default: true)
      @repository_1.valid?
      @repository_1.build_extra(default_branch: 'master', key: RedmineGitHosting::Utils::Crypto.generate_secret(64), git_https: true)
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
        expect(RedmineGitHosting::Commands).to receive(:sudo_git_objects_count).with('repositories/redmine/project-parent/project-child.git/objects')
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
          @repository_1.extra[:git_http]   = false
          @repository_1.extra[:git_https]  = false
          @repository_1.extra[:git_go]     = false
          @repository_1.extra[:git_ssh]    = false
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
          @repository_1.extra[:git_http]   = true
          @repository_1.extra[:git_https]  = true
          @repository_1.extra[:git_go]     = true
          @repository_1.extra[:git_ssh]    = true
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
          @repository_1.extra[:git_http]   = false
          @repository_1.extra[:git_https]  = false
          @repository_1.extra[:git_go]     = false
          @repository_1.extra[:git_ssh]    = false
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
          @repository_1.extra[:git_http]   = false
          @repository_1.extra[:git_https]  = false
          @repository_1.extra[:git_go]     = false
          @repository_1.extra[:git_ssh]    = true
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
          @repository_1.extra[:git_http]   = true
          @repository_1.extra[:git_https]  = false
          @repository_1.extra[:git_go]     = false
          @repository_1.extra[:git_ssh]    = false
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
          @repository_1.extra[:git_http]   = false
          @repository_1.extra[:git_https]  = true
          @repository_1.extra[:git_go]     = false
          @repository_1.extra[:git_ssh]    = false
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
          @repository_1.extra[:git_http]   = true
          @repository_1.extra[:git_https]  = true
          @repository_1.extra[:git_go]     = false
          @repository_1.extra[:git_ssh]    = false
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

  include_context 'flat_organisation'
  include_context 'hierarchical_organisation'
end
