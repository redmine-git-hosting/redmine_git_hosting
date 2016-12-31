require_dependency 'member'

module RedmineGitHosting
  module Patches
    module MemberPatch

      include RedmineGitHosting::GitoliteAccessor::Methods

      def self.prepended(base)
        base.class_eval do
          after_commit :update_project
        end
      end

      private

        def update_project
          options = { message: "Membership changes on project '#{project}', update!" }
          gitolite_accessor.update_projects([project.id], options)
        end

    end
  end
end

unless Member.included_modules.include?(RedmineGitHosting::Patches::MemberPatch)
  Member.send(:prepend, RedmineGitHosting::Patches::MemberPatch)
end
