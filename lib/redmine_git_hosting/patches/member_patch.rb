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
          GitHosting.logger.info "Membership changes on project '#{self.project}', update!"
          GitHosting.resync_gitolite({ :command => :update_members, :object => self.project.id })
        end

      end

    end
  end
end

unless Member.included_modules.include?(RedmineGitHosting::Patches::MemberPatch)
  Member.send(:include, RedmineGitHosting::Patches::MemberPatch)
end
