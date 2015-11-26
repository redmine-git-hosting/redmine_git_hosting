require_dependency 'repository'

module RedmineGitHosting
  module Patches
    module RepositoryPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
      end


      module InstanceMethods

        # This is the (possibly non-unique) basename for the Gitolite repository
        #
        def redmine_name
          identifier.blank? ? project.identifier : identifier
        end

      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
