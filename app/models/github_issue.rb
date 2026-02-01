# frozen_string_literal: true

class GithubIssue < RedmineGitHosting.old_redmine? ? ActiveRecord::Base : ApplicationRecord
  ## Relations
  belongs_to :issue

  ## Validations
  validates :github_id, presence: true
  validates :issue_id,  presence: true, uniqueness: { scope: :github_id }
end
