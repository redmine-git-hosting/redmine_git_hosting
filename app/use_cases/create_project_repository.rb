class CreateProjectRepository
  unloadable

  attr_reader :project


  def initialize(project)
    @project = project
  end


  def call
    create_project_repository
  end


  private


    def create_project_repository
      if project.module_enabled?('repository') && RedmineGitHosting::Config.all_projects_use_git?
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
      { create_readme_file: RedmineGitHosting::Config.init_repositories_on_create? }
    end

end
