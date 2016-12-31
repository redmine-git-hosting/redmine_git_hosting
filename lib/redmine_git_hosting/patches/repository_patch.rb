require_dependency 'repository'

module RedmineGitHosting
  module Patches
    module RepositoryPatch

      # This is the (possibly non-unique) basename for the Gitolite repository
      #
      def redmine_name
        identifier.blank? ? project.identifier : identifier
      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:prepend, RedmineGitHosting::Patches::RepositoryPatch)
end
