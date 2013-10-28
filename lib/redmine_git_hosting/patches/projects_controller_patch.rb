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
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          # Turn off updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual creation
          create_without_git_hosting(&block)

          # Only create/fixup repo if project creation worked
          if validate_parent_id && @project.save
            # Fix up repository
            git_repo_init

            # Adjust daemon status
            disable_git_daemon_if_not_public
          end

          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(true)
        end


        def update_with_git_hosting(&block)
          # Turn off updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          update_without_git_hosting(&block)

          # Adjust daemon status
          disable_git_daemon_if_not_public

          if @project.gitolite_repos.detect {|repo| repo.url != GitHosting.repository_path(repo) || repo.url != repo.root_url}
            # Hm... something about parent hierarchy changed.  Update us and our children
            GitHostingObserver.set_update_active(@project, :descendants)
          else
            # Reenable updates to perform a single update
            GitHostingObserver.set_update_active(true)
          end
        end


        def destroy_with_git_hosting(&block)
          # Turn off updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          destroy_without_git_hosting(&block)

          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(true)
        end


        def archive_with_git_hosting(&block)
          # Turn off updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          archive_without_git_hosting(&block)

          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(@project, :archive)
        end


        def unarchive_with_git_hosting(&block)
          # Turn off updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          unarchive_without_git_hosting(&block)

          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(@project)
        end


        private


        def git_repo_init
          users = @project.member_principals.map(&:user).compact.uniq
          if users.length == 0
            membership = Member.new(
              :principal  => User.current,
              :project_id => @project.id,
              :role_ids   => [3]
            )
            membership.save
          end

          if @project.module_enabled?('repository') && GitHostingConf.all_projects_use_git?
            # Create new repository
            repo = Repository.factory("Git")
            if GitHosting.multi_repos?
              @project.repositories << repo
            else
              @project.repository = repo
            end
            #GitHosting.logger.info "User '#{User.current.login}' created a new repository '#{GitHosting.repository_name(repository)}'"
            #GithostingShellWorker.perform_async({ :command => :add_repository, :object => repository.id })
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
          #GitHosting.logger.info "Set Git daemon for repositories of project : '#{@project}'"
          #GithostingShellWorker.perform_async({ :command => :update_project, :object => @project.id })
        end

      end

    end
  end
end

unless ProjectsController.included_modules.include?(RedmineGitHosting::Patches::ProjectsControllerPatch)
  ProjectsController.send(:include, RedmineGitHosting::Patches::ProjectsControllerPatch)
end
