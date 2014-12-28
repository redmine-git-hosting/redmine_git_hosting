require_dependency 'repository'

module RedmineGitHosting
  module Patches
    module RepositoryPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.class_eval do
          unloadable

          class << self
            alias_method_chain :factory, :git_hosting
          end
        end
      end


      module ClassMethods

        def factory_with_git_hosting(klass_name, *args)
          new_repo = factory_without_git_hosting(klass_name, *args)
          if new_repo.is_a?(::Repository::Xitolite) && new_repo.extra.nil?
            # Note that this autoinitializes default values and hook key
            RedmineGitHosting.logger.error("Automatic initialization of RepositoryGitExtra failed for #{self.project.to_s}")
          end
          new_repo
        end

      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
