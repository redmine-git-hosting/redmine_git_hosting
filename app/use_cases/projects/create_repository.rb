module Projects
  class CreateRepository < Base

    def call
      create_project_repository
    end


    private


      def create_project_repository
        # Create new repository
        repository = Repository.factory('Xitolite')
        repository.is_default = true
        repository.extra_info = {}
        repository.extra_info['extra_report_last_commit'] = '1'

        # Save it to database
        project.repositories << repository

        # Create it in Gitolite
        Repositories::Create.call(repository, creation_options)
      end


      def creation_options
        { create_readme_file: RedmineGitHosting::Config.init_repositories_on_create? }
      end

  end
end
