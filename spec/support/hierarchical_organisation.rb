RSpec.shared_context 'hierarchical_organisation' do

  ##############################################################
  #                                                            #
  #  HIERARCHICAL ORGANISATION / NON-UNIQUE REPOSITORIES TESTS #
  #                                                            #
  ##############################################################

  NON_UNIQUE_REPOSITORIES_MATRIX = {
    repository_1: {
      is_default:                    true,
      identifier:                    '',
      url:                           'repositories/redmine/project-parent/project-child.git',
      root_url:                      'repositories/redmine/project-parent/project-child.git',
      git_cache_id:                  'project-child',
      redmine_name:                  'project-child',
      gitolite_repository_path:      'repositories/redmine/project-parent/project-child.git',
      gitolite_full_repository_path: '/home/git/repositories/redmine/project-parent/project-child.git',
      gitolite_repository_name:      'redmine/project-parent/project-child',
      redmine_repository_path:       'project-parent/project-child',
      new_repository_name:           'redmine/project-parent/project-child',
      old_repository_name:           'redmine/project-parent/project-child',
      http_user_login:               '',
      git_access_path:               'redmine/project-parent/project-child.git',
      http_access_path:              'git/project-parent/project-child.git',
      ssh_url:                       "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child.git",
      git_url:                       'git://localhost/redmine/project-parent/project-child.git',
      http_url:                      'http://localhost/git/project-parent/project-child.git',
      https_url:                     'https://localhost/git/project-parent/project-child.git',
    },

    repository_2: {
      is_default:                    false,
      identifier:                    'repo-test',
      url:                           'repositories/redmine/project-parent/project-child/repo-test.git',
      root_url:                      'repositories/redmine/project-parent/project-child/repo-test.git',
      git_cache_id:                  'project-child/repo-test',
      redmine_name:                  'repo-test',
      gitolite_repository_path:      'repositories/redmine/project-parent/project-child/repo-test.git',
      gitolite_full_repository_path: '/home/git/repositories/redmine/project-parent/project-child/repo-test.git',
      gitolite_repository_name:      'redmine/project-parent/project-child/repo-test',
      redmine_repository_path:       'project-parent/project-child/repo-test',
      new_repository_name:           'redmine/project-parent/project-child/repo-test',
      old_repository_name:           'redmine/project-parent/project-child/repo-test',
      http_user_login:               '',
      git_access_path:               'redmine/project-parent/project-child/repo-test.git',
      http_access_path:              'git/project-parent/project-child/repo-test.git',
      ssh_url:                       "ssh://#{GIT_USER}@localhost/redmine/project-parent/project-child/repo-test.git",
      git_url:                       'git://localhost/redmine/project-parent/project-child/repo-test.git',
      http_url:                      'http://localhost/git/project-parent/project-child/repo-test.git',
      https_url:                     'https://localhost/git/project-parent/project-child/repo-test.git',
    },

    repository_3: {
      is_default:                    true,
      identifier:                    '',
      url:                           'repositories/redmine/project-parent.git',
      root_url:                      'repositories/redmine/project-parent.git',
      git_cache_id:                  'project-parent',
      redmine_name:                  'project-parent',
      gitolite_repository_path:      'repositories/redmine/project-parent.git',
      gitolite_full_repository_path: '/home/git/repositories/redmine/project-parent.git',
      gitolite_repository_name:      'redmine/project-parent',
      redmine_repository_path:       'project-parent',
      new_repository_name:           'redmine/project-parent',
      old_repository_name:           'redmine/project-parent',
      http_user_login:               '',
      git_access_path:               'redmine/project-parent.git',
      http_access_path:              'git/project-parent.git',
      ssh_url:                       "ssh://#{GIT_USER}@localhost/redmine/project-parent.git",
      git_url:                       'git://localhost/redmine/project-parent.git',
      http_url:                      'http://localhost/git/project-parent.git',
      https_url:                     'https://localhost/git/project-parent.git',
    },

    repository_4: {
      is_default:                    false,
      identifier:                    'repo-test',
      url:                           'repositories/redmine/project-parent/repo-test.git',
      root_url:                      'repositories/redmine/project-parent/repo-test.git',
      git_cache_id:                  'project-parent/repo-test',
      redmine_name:                  'repo-test',
      gitolite_repository_path:      'repositories/redmine/project-parent/repo-test.git',
      gitolite_full_repository_path: '/home/git/repositories/redmine/project-parent/repo-test.git',
      gitolite_repository_name:      'redmine/project-parent/repo-test',
      redmine_repository_path:       'project-parent/repo-test',
      new_repository_name:           'redmine/project-parent/repo-test',
      old_repository_name:           'redmine/project-parent/repo-test',
      http_user_login:               '',
      git_access_path:               'redmine/project-parent/repo-test.git',
      http_access_path:              'git/project-parent/repo-test.git',
      ssh_url:                       "ssh://#{GIT_USER}@localhost/redmine/project-parent/repo-test.git",
      git_url:                       'git://localhost/redmine/project-parent/repo-test.git',
      http_url:                      'http://localhost/git/project-parent/repo-test.git',
      https_url:                     'https://localhost/git/project-parent/repo-test.git',
    }
  }

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

    NON_UNIQUE_REPOSITORIES_MATRIX.each do |repo, attributes|
      describe repo do
        attributes.each do |key, value|
          if value == true || value == false
            it { expect(instance_variable_get("@#{repo}").send(key)).to be value }
          else
            it { expect(instance_variable_get("@#{repo}").send(key)).to eq value }
          end
        end
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
end
