require_dependency 'roles_controller'

module RedmineGitHosting
  module Patches
    module RolesControllerPatch

      include RedmineGitHosting::GitoliteAccessor::Methods

      def create
        super
        call_gitolite('created')
      end


      def update
        super
        call_gitolite('modified')
      end


      def destroy
        super
        call_gitolite('deleted')
      end


      def permissions
        super
        call_gitolite('modified') if request.post?
      end


      private


        def call_gitolite(message)
          options = { message: "Role has been #{message}, resync all projects (active or closed)..." }
          gitolite_accessor.update_projects('active_or_closed', options)
        end

    end
  end
end

unless RolesController.included_modules.include?(RedmineGitHosting::Patches::RolesControllerPatch)
  RolesController.send(:prepend, RedmineGitHosting::Patches::RolesControllerPatch)
end
