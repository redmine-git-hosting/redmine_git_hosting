class CreateProjectRepository
  unloadable

  include UseCaseBase

  attr_reader :project


  def initialize(project)
    @project = project
    super
  end


  def call
    create_project_repository
    super
  end


  private


    def create_project_repository
      if project.module_enabled?('repository') && RedmineGitHosting::Config.get_setting(:all_projects_use_git, true)
        # Create new repository
        repository = Repository.factory('Xitolite')
        repository.is_default = true
        repository.extra_info = {}
        repository.extra_info['extra_report_last_commit'] = '1'

        # Save it to database
        project.repositories << repository

        # Create it in Gitolite
        CreateRepository.new(repository, creation_options).call
      end
    end


    def creation_options
      { create_readme_file: RedmineGitHosting::Config.get_setting(:init_repositories_on_create, true) }
    end

end
