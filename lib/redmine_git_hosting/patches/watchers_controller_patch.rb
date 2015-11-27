require_dependency 'watchers_controller'

module RedmineGitHosting
  module Patches
    module WatchersControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, RedmineGitHosting::GitoliteAccessor::Methods)
        base.class_eval do
          alias_method_chain :create,  :git_hosting
          alias_method_chain :destroy, :git_hosting
          alias_method_chain :watch,   :git_hosting
          alias_method_chain :unwatch, :git_hosting
        end
      end


      module InstanceMethods

        def create_with_git_hosting(&block)
          create_without_git_hosting(&block)
          update_repository(@watched)
        end


        def destroy_with_git_hosting(&block)
          destroy_without_git_hosting(&block)
          update_repository(@watched)
        end


        def watch_with_git_hosting(&block)
          watch_without_git_hosting(&block)
          update_repository(@watchables.first)
        end


        def unwatch_with_git_hosting(&block)
          unwatch_without_git_hosting(&block)
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
end

unless WatchersController.included_modules.include?(RedmineGitHosting::Patches::WatchersControllerPatch)
  WatchersController.send(:include, RedmineGitHosting::Patches::WatchersControllerPatch)
end
