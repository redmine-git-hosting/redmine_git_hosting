require_dependency 'member'

module RedmineGitHosting
  module Patches
    module MemberPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          after_commit :update_project
        end
      end

      module InstanceMethods

        private

          def update_project
            options = { message: "Membership changes on project '#{project}', update!" }
            UpdateProject.new(project, options).call
          end

      end

    end
  end
end

unless Member.included_modules.include?(RedmineGitHosting::Patches::MemberPatch)
  Member.send(:include, RedmineGitHosting::Patches::MemberPatch)
end
