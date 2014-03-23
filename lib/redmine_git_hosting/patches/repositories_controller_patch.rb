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
          if @repository.is_a?(Repository::Git) and @rev.blank?
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

              if params[:extra][:git_daemon] == 'true'
                params[:extra][:git_daemon] = 1
              else
                params[:extra][:git_daemon] = 0
              end

              if params[:extra][:git_notify] == 'true'
                params[:extra][:git_notify] = 1
              else
                params[:extra][:git_notify] = 0
              end

              @repository.extra.update_attributes(params[:extra])

              options = params[:repository][:create_readme] == 'true' ? {:create_readme_file => true} : {:create_readme_file => false}

              RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' created a new repository '#{@repository.gitolite_repository_name}'" }
              RedmineGitolite::GitHosting.resync_gitolite({ :command => :add_repository, :object => @repository.id, :options => options })
            end
          end
        end


        def update_with_git_hosting(&block)
          update_without_git_hosting(&block)

          if @repository.is_a?(Repository::Git)
            if !@repository.errors.any?

              if params[:extra][:git_daemon] == 'true'
                params[:extra][:git_daemon] = 1
              else
                params[:extra][:git_daemon] = 0
              end

              if params[:extra][:git_notify] == 'true'
                params[:extra][:git_notify] = 1
              else
                params[:extra][:git_notify] = 0
              end

              update_default_branch = false

              if params[:extra].has_key?(:default_branch) && @repository.extra[:default_branch] != params[:extra][:default_branch]
                update_default_branch = true
              end

              ## Update attributes
              @repository.extra.update_attributes(params[:extra])

              ## Update repository
              RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified repository '#{@repository.gitolite_repository_name}'" }
              RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository, :object => @repository.id })

              ## Update repository default branch
              if update_default_branch
                RedmineGitolite::GitHosting.logger.info { "User '#{User.current.login}' has modified default_branch of '#{@repository.gitolite_repository_name}' ('#{@repository.extra[:default_branch]}')" }
                RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository_default_branch, :object => @repository.id })
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
              RedmineGitolite::GitHosting.resync_gitolite({ :command => :delete_repositories, :object => [repository_data] })
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
