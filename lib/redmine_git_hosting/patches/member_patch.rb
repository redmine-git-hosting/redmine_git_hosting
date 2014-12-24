require_dependency 'member'

module RedmineGitHosting
  module Patches
    module MemberPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          after_commit :update_member
        end
      end

      module InstanceMethods

        private

          def update_member
            UpdateProject.new(project, "Membership changes on project '#{project}', update!").call
          end

      end

    end
  end
end

unless Member.included_modules.include?(RedmineGitHosting::Patches::MemberPatch)
  Member.send(:include, RedmineGitHosting::Patches::MemberPatch)
end
