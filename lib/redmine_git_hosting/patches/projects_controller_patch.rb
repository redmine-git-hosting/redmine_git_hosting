require_dependency 'projects_controller'

module RedmineGitHosting
  module Patches
    module ProjectsControllerPatch
      include RedmineGitHosting::GitoliteAccessor::Methods

      def self.prepended(base)
        base.class_eval do
          helper :bootstrap_kit
          helper :additionals_clipboardjs
          helper :extend_projects
        end
      end

      def create
        super
        # Only create repo if project creation worked
        create_project_repository if valid_project?
      end

      def update
        super
        if @project.gitolite_repos.detect { |repo| repo.url != repo.gitolite_repository_path || repo.url != repo.root_url }
          # Hm... something about parent hierarchy changed.  Update us and our children
          move_project_hierarchy
        else
          update_project("Set Git daemon for repositories of project : '#{@project}'")
        end
      end

      def destroy
        # Build repositories list before project destruction.
        repositories_list = repositories_to_destroy
        # Destroy project
        super
        # Destroy repositories
        destroy_repositories(repositories_list) if api_request? || params[:confirm]
      end

      def archive
        super
        update_project_hierarchy("User '#{User.current.login}' has archived project '#{@project}', update it !")
      end

      def unarchive
        super
        update_project("User '#{User.current.login}' has unarchived project '#{@project}', update it !")
      end

      def close
        super
        update_project_hierarchy("User '#{User.current.login}' has closed project '#{@project}', update it !")
      end

      def reopen
        super
        update_project_hierarchy("User '#{User.current.login}' has reopened project '#{@project}', update it !")
      end

      private

      def valid_project?
        if Rails::VERSION::MAJOR == 3
          validate_parent_id && @project.save
        else
          @project.save
        end
      end

      # Call UseCase object that will complete Project repository creation :
      # it will create the Repository::Xitolite association, the GitExtra association and then
      # the repository in Gitolite.
      #
      def create_project_repository
        if @project.module_enabled?('repository') && RedmineGitHosting::Config.all_projects_use_git?
          if Setting.enabled_scm.include?('Xitolite')
            Projects::CreateRepository.call(@project)
          else
            flash[:error] = l(:error_xitolite_repositories_disabled)
          end
        end
      end

      def move_project_hierarchy
        gitolite_accessor.move_project_hierarchy(@project)
      end

      def update_project(message)
        options = { message: message }
        Projects::Update.call(@project, options)
      end

      def update_project_hierarchy(message)
        options = { message: message }
        gitolite_accessor.update_projects(hierarchy_to_update, options)
      end

      def hierarchy_to_update
        # Only take projects that have Git repos.
        @project.self_and_descendants.uniq.select { |p| p.gitolite_repos.any? }.map(&:id)
      end

      def destroy_repositories(repositories_list)
        options = { message: "User '#{User.current.login}' has destroyed project '#{@project}', delete all Gitolite repositories !" }
        gitolite_accessor.destroy_repositories(repositories_list, options)
      end

      def repositories_to_destroy
        destroy_repositories = []

        # Get all projects hierarchy
        projects = @project.self_and_descendants

        # Only take projects that have Git repos.
        git_projects = projects.uniq.select { |p| p.gitolite_repos.any? }

        git_projects.reverse.each do |project|
          project.gitolite_repos.reverse.each do |repository|
            destroy_repositories << repository.data_for_destruction
          end
        end

        destroy_repositories
      end
    end
  end
end

unless ProjectsController.included_modules.include?(RedmineGitHosting::Patches::ProjectsControllerPatch)
  ProjectsController.send(:prepend, RedmineGitHosting::Patches::ProjectsControllerPatch)
end
