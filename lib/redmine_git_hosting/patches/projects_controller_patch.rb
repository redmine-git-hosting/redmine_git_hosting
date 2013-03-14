module GitHosting
  module Patches
    module ProjectsControllerPatch

      def git_repo_init
        users = @project.member_principals.map(&:user).compact.uniq
        if users.length == 0
          membership = Member.new(
              :principal=>User.current,
              :project_id=>@project.id,
              :role_ids=>[3]
          )
          membership.save
        end

        if @project.module_enabled?('repository') && Setting.plugin_redmine_git_hosting['allProjectsUseGit'] == "true"
          # Create new repository
          repo = Repository.factory("Git")
          if GitHosting.multi_repos?
            @project.repositories << repo
          else
            @project.repository = repo
          end
        end
      end

      def disable_git_daemon_if_not_public
        # Go through all gitolite repos and diable git_daemon if necessary
        @project.gl_repos.each do |repo|
          if repo.extra.git_daemon == 1 && (not @project.is_public )
            repo.extra.git_daemon = 0;
            repo.extra.save
            repo.save # Trigger update_repositories
          end
        end
      end

      def create_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual creation
        create_without_disable_update

        # Only create/fixup repo if project creation worked
        if validate_parent_id && @project.save
          # Fix up repository
          git_repo_init

          # Adjust daemon status
          disable_git_daemon_if_not_public
        end

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true);
      end

      def update_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        update_without_disable_update

        # Adjust daemon status
        disable_git_daemon_if_not_public

        if @project.gl_repos.detect {|repo| repo.url != GitHosting::repository_path(repo) || repo.url != repo.root_url}
          # Hm... something about parent hierarchy changed.  Update us and our children
          GitHostingObserver.set_update_active(@project, :descendants)
        else
          # Reenable updates to perform a single update
          GitHostingObserver.set_update_active(true);
        end
      end

      def destroy_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        destroy_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true);
      end

      def archive_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        archive_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(@project, :archive);
      end

      def unarchive_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        unarchive_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(@project);
      end

      def settings_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false);

        # Do actual update
        settings_without_disable_update

        # Reenable updates to perform a single update
        if @project.module_enabled?(:repository)
          GitHostingObserver.set_update_active(@project);
        else
          GitHostingObserver.set_update_active(:archive);
        end
      end

      def self.included(base)
        base.class_eval do
          unloadable
        end
        base.send(:alias_method_chain, :create, :disable_update)
        base.send(:alias_method_chain, :update, :disable_update)
        base.send(:alias_method_chain, :destroy, :disable_update)
        base.send(:alias_method_chain, :archive, :disable_update)
        base.send(:alias_method_chain, :unarchive, :disable_update)
        base.send(:alias_method_chain, :settings, :disable_update)
      end

    end
  end
end

# Patch in changes
ProjectsController.send(:include, GitHosting::Patches::ProjectsControllerPatch)
