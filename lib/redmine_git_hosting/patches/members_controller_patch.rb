module RedmineGitHosting
  module Patches
    module MembersControllerPatch

      def self.included(base)
        base.class_eval do
          unloadable
          helper :repositories
        end

        begin
          # RESTfull (post-1.4)
          base.send(:alias_method_chain, :create, :disable_update)
        rescue
          # Not RESTfull (pre-1.4)
          base.send(:alias_method_chain, :new, :disable_update) rescue nil
        end

        begin
          # RESTfull (post-1.4)
          base.send(:alias_method_chain, :update, :disable_update)
        rescue
          # Not RESTfull (pre-1.4)
          base.send(:alias_method_chain, :edit, :disable_update) rescue nil
        end

        base.send(:alias_method_chain, :destroy, :disable_update) rescue nil

        # This patch only needed when repository settings in same set
        # if tabs as members (i.e. pre-1.4, single repo)
        # (Note that patches not stabilized yet, so cannot just call:
        # Project.multi_repos?
        if !GitHosting.multi_repos?
          base.send(:alias_method_chain, :render, :trigger_refresh) rescue nil
        end
      end

      # pre-1.4 (Non RESTfull)
      def new_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false)

        # Do actual update
        new_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true)
      end

      # post-1.4 (RESTfull)
      def create_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false)

        # Do actual update
        create_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true)
      end

      # pre-1.4 (Non RESTfull)
      def edit_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false)

        # Do actual update
        edit_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true)
      end

      # post-1.4 (RESTfull)
      def update_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false)

        # Do actual update
        update_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(true)
      end

      def destroy_with_disable_update
        # Turn of updates during repository update
        GitHostingObserver.set_update_active(false)

        # Do actual update
        destroy_without_disable_update

        # Reenable updates to perform a single update
        GitHostingObserver.set_update_active(:delete => true)
      end

      # Need to make sure that we can re-render the repository settings page
      # (Only for pre-1.4, i.e. single repo/project)
      def render_with_trigger_refresh(*options, &myblock)
        doing_update = options.detect {|x| x==:update || (x.is_a?(Hash) && x[:update])}
        if !doing_update
          render_without_trigger_refresh(*options, &myblock)
        else
          # For repository partial
          render_without_trigger_refresh *options do |page|
            yield page
            if (@repository ||= @project.repository) && (@repository.is_a?(Repository::Git))
              page.replace_html "tab-content-repository", :partial => 'projects/settings/repository'
            end
          end
        end
      end

    end
  end
end

unless MembersController.included_modules.include?(RedmineGitHosting::Patches::MembersControllerPatch)
  MembersController.send(:include, RedmineGitHosting::Patches::MembersControllerPatch)
end
