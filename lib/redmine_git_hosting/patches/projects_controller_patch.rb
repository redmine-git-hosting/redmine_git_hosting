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
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)
          # Only create repo if project creation worked
          if validate_parent_id && @project.save
            CreateProjectRepository.new(@project).call
          end
        end


        def update_with_git_hosting(&block)
          update_without_git_hosting(&block)
          if @project.gitolite_repos.detect {|repo| repo.url != repo.gitolite_repository_path || repo.url != repo.root_url}
            # Hm... something about parent hierarchy changed.  Update us and our children
            MoveProjectHierarchy.new(@project).call
          else
            UpdateProject.new(@project).call
          end
        end


        def destroy_with_git_hosting(&block)
          repositories_list = repositories_to_destroy
          destroy_without_git_hosting(&block)
          if api_request? || params[:confirm]
            RedmineGitolite::GitHosting.resync_gitolite(:delete_repositories, repositories_list)
          end
        end


        def archive_with_git_hosting(&block)
          archive_without_git_hosting(&block)
          UpdateProjectHierarchy.new(@project, "Project has been archived, update it : '#{@project}'").call
        end


        def unarchive_with_git_hosting(&block)
          unarchive_without_git_hosting(&block)
          UpdateProject.new(@project, "Project has been unarchived, update it : '#{@project}'").call
        end


        def close_with_git_hosting(&block)
          close_without_git_hosting(&block)
          UpdateProjectHierarchy.new(@project, "Project has been closed, update it : '#{@project}'").call
        end


        def reopen_with_git_hosting(&block)
          reopen_without_git_hosting(&block)
          UpdateProjectHierarchy.new(@project, "Project has been reopened, update it : '#{@project}'").call
        end


        private


          def repositories_to_destroy
            destroy_repositories = []

            # Get all projects hierarchy
            projects = @project.self_and_descendants

            # Only take projects that have Git repos.
            git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}

            git_projects.reverse.each do |project|
              project.gitolite_repos.reverse.each do |repository|
                repository_data = {}
                repository_data['repo_name']   = repository.gitolite_repository_name
                repository_data['repo_path']   = repository.gitolite_repository_path
                destroy_repositories << repository_data
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
