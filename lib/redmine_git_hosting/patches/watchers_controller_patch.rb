require_dependency 'watchers_controller'

module RedmineGitHosting
  module Patches
    module WatchersControllerPatch

      include RedmineGitHosting::GitoliteAccessor::Methods

      def create
        super
        update_repository(@watched)
      end


      def destroy
        super
        update_repository(@watched)
      end


      def watch
        super
        update_repository(@watchables.first)
      end


      def unwatch
        super
        update_repository(@watchables.first)
      end


      private


        def update_repository(repo)
          return if !repo.is_a?(Repository::Xitolite)
          options = { message: "Watcher changes on repository '#{repo}', update!" }
          gitolite_accessor.update_repository(repo, options)
        end

    end
  end
end

unless WatchersController.included_modules.include?(RedmineGitHosting::Patches::WatchersControllerPatch)
  WatchersController.send(:prepend, RedmineGitHosting::Patches::WatchersControllerPatch)
end
