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

          include GitHostingHelper
          helper :git_hosting
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)

          # Only create repo if project creation worked
          if validate_parent_id && @project.save
            git_repo_init
          end
        end


        def update_with_git_hosting(&block)
          update_without_git_hosting(&block)

          update = true

          if @project.gitolite_repos.detect {|repo| repo.url != repo.gitolite_repository_path || repo.url != repo.root_url}
            # Hm... something about parent hierarchy changed.  Update us and our children
            RedmineGitolite::GitHosting.logger.info { "Move repositories of project : '#{@project}'" }
            RedmineGitolite::GitHosting.resync_gitolite({ :command => :move_repositories, :object => @project.id })
            update = false
          end

          # Adjust daemon status
          disable_git_daemon_if_not_public if update
        end


        def destroy_with_git_hosting(&block)
          destroy_repositories = []

          projects = @project.self_and_descendants

          # Only take projects that have Git repos.
          git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}
          return if git_projects.empty?

          git_projects.reverse.each do |project|
            project.gitolite_repos.reverse.each do |repository|
              repository_data = {}
              repository_data['repo_name']   = repository.gitolite_repository_name
              repository_data['repo_path']   = repository.gitolite_repository_path
              destroy_repositories.push(repository_data)
            end
          end

          destroy_without_git_hosting(&block)

          if api_request? || params[:confirm]
            RedmineGitolite::GitHosting.resync_gitolite({ :command => :delete_repositories, :object => destroy_repositories })
          end
        end


        def archive_with_git_hosting(&block)
          archive_without_git_hosting(&block)

          projects = @project.self_and_descendants

          # Only take projects that have Git repos.
          git_projects = projects.uniq.select{|p| p.gitolite_repos.any?}
          return if git_projects.empty?

          project_list = []
          git_projects.each do |project|
            project_list.push(project.id)
          end

          RedmineGitolite::GitHosting.logger.info { "Project has been archived, update it : '#{@project}'" }
          RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_projects, :object => project_list })
        end


        def unarchive_with_git_hosting(&block)
          # Do actual update
          unarchive_without_git_hosting(&block)

          RedmineGitolite::GitHosting.logger.info { "Project has been unarchived, update it : '#{@project}'" }
          RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_project, :object => @project.id })
        end


        private


        def git_repo_init
          if @project.module_enabled?('repository') && RedmineGitolite::ConfigRedmine.get_setting(:all_projects_use_git, true)
            # Create new repository
            repository = Repository.factory("Git")
            repository.is_default = true
            @project.repositories << repository
            RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository '#{repository.gitolite_repository_name}'" }
            RedmineGitolite::GitHosting.resync_gitolite({ :command => :add_repository, :object => repository.id })

            if RedmineGitolite::ConfigRedmine.get_setting(:init_repositories_on_create, true)
              RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository with README '#{repository.gitolite_repository_name}', create README file" }
              RedmineGitolite::GitHosting.resync_gitolite({ :command => :create_readme_file, :object => repository.id })
            end
          end
        end


        def disable_git_daemon_if_not_public
          # Go through all gitolite repos and diable Git daemon if necessary
          @project.gitolite_repos.each do |repository|
            if repository.extra.git_daemon == 1 && !@project.is_public
              repository.extra.git_daemon = 0
              repository.extra.save
            end
          end
          RedmineGitolite::GitHosting.logger.info { "Set Git daemon for repositories of project : '#{@project}'" }
          RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_project, :object => @project.id })
        end

      end

    end
  end
end

unless ProjectsController.included_modules.include?(RedmineGitHosting::Patches::ProjectsControllerPatch)
  ProjectsController.send(:include, RedmineGitHosting::Patches::ProjectsControllerPatch)
end
