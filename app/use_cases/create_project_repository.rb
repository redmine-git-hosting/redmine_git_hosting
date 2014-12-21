class CreateProjectRepository
  unloadable

  include UseCaseBase

  attr_reader :project


  def initialize(project)
    @project = project
    super
  end


  def call
    create_repository
    super
  end


  private


    def create_repository
      if project.module_enabled?('repository') && RedmineGitolite::Config.get_setting(:all_projects_use_git, true)
        # Create new repository
        repository = Repository.factory('Gitolite')
        repository.is_default = true
        repository.extra_info = {}
        repository.extra_info['extra_report_last_commit'] = '1'
        project.repositories << repository

        RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository '#{repository.gitolite_repository_name}'" }
        RedmineGitolite::GitHosting.resync_gitolite(:add_repository, repository.id, creation_options)
      end
    end


    def creation_options
      { :create_readme_file => RedmineGitolite::Config.get_setting(:init_repositories_on_create, true) }
    end

end
