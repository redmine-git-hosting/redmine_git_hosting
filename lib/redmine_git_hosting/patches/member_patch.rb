require_dependency 'member'

module RedmineGitHosting
  module Patches
    module MemberPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, RedmineGitHosting::GitoliteAccessor::Methods)
        base.class_eval do
          after_commit :update_project
        end
      end


      module InstanceMethods

        private

          def update_project
            options = { message: "Membership changes on project '#{project}', update!" }
            gitolite_accessor.update_projects([project.id], options)
          end

      end

    end
  end
end

unless Member.included_modules.include?(RedmineGitHosting::Patches::MemberPatch)
  Member.send(:include, RedmineGitHosting::Patches::MemberPatch)
end
