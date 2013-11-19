module RedmineGitHosting
  module Patches
    module RolesControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          begin
            # RESTfull (post-1.4)
            alias_method_chain :create,   :git_hosting
          rescue
            # Not RESTfull (pre-1.4)
            alias_method_chain :new,      :git_hosting rescue nil
          end

          begin
            # RESTfull (post-1.4)
            alias_method_chain :update,   :git_hosting
          rescue
            # Not RESTfull (pre-1.4)
            alias_method_chain :edit,     :git_hosting rescue nil
          end

          alias_method_chain :destroy,     :git_hosting rescue nil
          alias_method_chain :permissions, :git_hosting rescue nil
        end
      end


      module InstanceMethods

        # Pre-1.4 (Not RESTfull)
        def new_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          new_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end

        # Post-1.4 (RESTfull)
        def create_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          create_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end

        # Pre-1.4 (Not RESTfull)
        def edit_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          edit_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end

        # Post-1.4 (RESTfull)
        def update_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          update_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end


        def permissions_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          permissions_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)

          #if request.post?
          #  resync_gitolite('modified')
          #end
        end


        def destroy_with_git_hosting(&block)
          GitHostingObserver.set_update_active(false)
          destroy_without_git_hosting(&block)
          GitHostingObserver.set_update_active(true)
        end


        private


        def resync_gitolite(message)
          projects = Project.active_or_archived.find(:all, :include => :repositories)
          if projects.length > 0
            GitHosting.logger.info "Role has been #{message}, resync all projects..."
            GitHosting.resync_gitolite({ :command => :update_all_projects, :object => projects.length })
          end
        end

      end

    end
  end
end

unless RolesController.included_modules.include?(RedmineGitHosting::Patches::RolesControllerPatch)
  RolesController.send(:include, RedmineGitHosting::Patches::RolesControllerPatch)
end
