require_dependency 'repositories_controller'

module RedmineGitHosting
  module Patches
    module RepositoriesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :show,    :git_hosting
          alias_method_chain :create,  :git_hosting
          alias_method_chain :update,  :git_hosting
          alias_method_chain :destroy, :git_hosting

          before_filter :set_current_tab, :only => :edit

          helper :git_hosting
        end
      end

      module InstanceMethods

        def show_with_git_hosting(&block)
          if @repository.is_a?(Repository::Git) && @repository.empty?
            # Fake list of repos
            @repositories = @project.gitolite_repos
            render :action => 'git_instructions'
          else
            show_without_git_hosting(&block)
          end
        end


        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)

          if @repository.is_a?(Repository::Git)
            if !@repository.errors.any?

              params[:extra][:git_daemon] = params[:extra][:git_daemon] == 'true' ? true : false
              params[:extra][:git_notify] = params[:extra][:git_notify] == 'true' ? true : false

              @repository.extra.update_attributes(params[:extra])

              options = params[:repository][:create_readme] == 'true' ? {:create_readme_file => true} : {:create_readme_file => false}

              RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository '#{@repository.gitolite_repository_name}'" }
              RedmineGitolite::GitHosting.resync_gitolite(:add_repository, @repository.id, options)
            end
          end
        end


        def update_with_git_hosting(&block)
          update_without_git_hosting(&block)

          if @repository.is_a?(Repository::Git)
            if !@repository.errors.any?

              params[:extra][:git_daemon] = params[:extra][:git_daemon] == 'true' ? true : false
              params[:extra][:git_notify] = params[:extra][:git_notify] == 'true' ? true : false

              update_default_branch = false

              if params[:extra].has_key?(:default_branch) && @repository.extra[:default_branch] != params[:extra][:default_branch]
                update_default_branch = true
              end

              ## Update attributes
              @repository.extra.update_attributes(params[:extra])

              ## Update repository
              RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified repository '#{@repository.gitolite_repository_name}'" }
              RedmineGitolite::GitHosting.resync_gitolite(:update_repository, @repository.id)

              ## Update repository default branch
              if update_default_branch
                RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified default_branch of '#{@repository.gitolite_repository_name}' ('#{@repository.extra[:default_branch]}')" }
                RedmineGitolite::GitHosting.resync_gitolite(:update_repository_default_branch, @repository.id)
              end
            end
          end
        end


        def destroy_with_git_hosting(&block)
          destroy_without_git_hosting(&block)

          if @repository.is_a?(Repository::Git)
            if !@repository.errors.any?
              RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has removed repository '#{@repository.gitolite_repository_name}'" }
              repository_data = {}
              repository_data['repo_name'] = @repository.gitolite_repository_name
              repository_data['repo_path'] = @repository.gitolite_repository_path
              RedmineGitolite::GitHosting.resync_gitolite(:delete_repositories, [repository_data])
            end
          end
        end


        private


        def set_current_tab
          @tab = params[:tab] || ""
        end

      end

    end
  end
end

unless RepositoriesController.included_modules.include?(RedmineGitHosting::Patches::RepositoriesControllerPatch)
  RepositoriesController.send(:include, RedmineGitHosting::Patches::RepositoriesControllerPatch)
end
