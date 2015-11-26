require_dependency 'projects_controller'

module RedmineGitHosting
  module Patches
    module ProjectsControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, RedmineGitHosting::GitoliteAccessor::Methods)
        base.class_eval do
          alias_method_chain :create,    :git_hosting
          alias_method_chain :update,    :git_hosting
          alias_method_chain :destroy,   :git_hosting
          alias_method_chain :archive,   :git_hosting
          alias_method_chain :unarchive, :git_hosting
          alias_method_chain :close,     :git_hosting
          alias_method_chain :reopen,    :git_hosting

          helper :redmine_bootstrap_kit
          helper :extend_projects
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)
          # Only create repo if project creation worked
          create_project_repository if valid_project?
        end


        def update_with_git_hosting(&block)
          update_without_git_hosting(&block)
          if @project.gitolite_repos.detect { |repo| repo.url != repo.gitolite_repository_path || repo.url != repo.root_url }
            # Hm... something about parent hierarchy changed.  Update us and our children
            move_project_hierarchy
          else
            update_project("Set Git daemon for repositories of project : '#{@project}'")
          end
        end


        def destroy_with_git_hosting(&block)
          # Build repositories list before project destruction.
          repositories_list = repositories_to_destroy
          # Destroy project
          destroy_without_git_hosting(&block)
          # Destroy repositories
          destroy_repositories(repositories_list) if api_request? || params[:confirm]
        end


        def archive_with_git_hosting(&block)
          archive_without_git_hosting(&block)
          update_project_hierarchy("User '#{User.current.login}' has archived project '#{@project}', update it !")
        end


        def unarchive_with_git_hosting(&block)
          unarchive_without_git_hosting(&block)
          update_project("User '#{User.current.login}' has unarchived project '#{@project}', update it !")
        end


        def close_with_git_hosting(&block)
          close_without_git_hosting(&block)
          update_project_hierarchy("User '#{User.current.login}' has closed project '#{@project}', update it !")
        end


        def reopen_with_git_hosting(&block)
          reopen_without_git_hosting(&block)
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
            @project.self_and_descendants.uniq.select { |p| p.gitolite_repos.any? }.map { |project| project.id }
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
end

unless ProjectsController.included_modules.include?(RedmineGitHosting::Patches::ProjectsControllerPatch)
  ProjectsController.send(:include, RedmineGitHosting::Patches::ProjectsControllerPatch)
end
