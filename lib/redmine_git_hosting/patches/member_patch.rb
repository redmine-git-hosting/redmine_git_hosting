module RedmineGitHosting
  module Patches
    module MemberPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          after_commit  :update_member
        end
      end

      module InstanceMethods

        private

        def update_member
          RedmineGitolite::GitHosting.logger.info { "Membership changes on project '#{self.project}', update!" }
          RedmineGitolite::GitHosting.resync_gitolite(:update_members, self.project.id)
        end

      end

    end
  end
end

unless Member.included_modules.include?(RedmineGitHosting::Patches::MemberPatch)
  Member.send(:include, RedmineGitHosting::Patches::MemberPatch)
end
