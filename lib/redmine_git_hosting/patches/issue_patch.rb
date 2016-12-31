require_dependency 'issue'

module RedmineGitHosting
  module Patches
    module IssuePatch

      def self.prepended(base)
        base.class_eval do
          has_one :github_issue, foreign_key: 'issue_id', class_name: 'GithubIssue', dependent: :destroy
        end
      end

    end
  end
end

unless Issue.included_modules.include?(RedmineGitHosting::Patches::IssuePatch)
  Issue.send(:prepend, RedmineGitHosting::Patches::IssuePatch)
end
