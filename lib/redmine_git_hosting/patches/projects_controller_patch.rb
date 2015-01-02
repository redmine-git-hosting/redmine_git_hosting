require_dependency 'projects_controller'

module RedmineGitHosting
  module Patches
    module ProjectsControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :create,    :git_hosting
          alias_method_chain :update,    :git_hosting
          alias_method_chain :destroy,   :git_hosting
          alias_method_chain :archive,   :git_hosting
          alias_method_chain :unarchive, :git_hosting
          alias_method_chain :close,     :git_hosting
          alias_method_chain :reopen,    :git_hosting

          helper :git_hosting
          helper :extend_projects
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)
          # Only create repo if project creation worked
          create_project_repository if validate_parent_id && @project.save
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


          def create_project_repository
            CreateProjectRepository.new(@project).call
          end


          def move_project_hierarchy
            MoveProjectHierarchy.new(@project).call
          end


          def update_project(message)
            options = { message: message }
            UpdateProject.new(@project, options).call
          end


          def update_project_hierarchy(message)
            options = { message: message }
            UpdateProjectHierarchy.new(@project, options).call
          end


          def destroy_repositories(repositories_list)
            options = { message: "User '#{User.current.login}' has destroyed project '#{@project}', delete all Gitolite repositories !" }
            DestroyRepositories.new(repositories_list, options).call
          end


          def repositories_to_destroy
            destroy_repositories = []

            # Get all projects hierarchy
            projects = @project.self_and_descendants

            # Only take projects that have Git repos.
            git_projects = projects.uniq.select{ |p| p.gitolite_repos.any? }

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
