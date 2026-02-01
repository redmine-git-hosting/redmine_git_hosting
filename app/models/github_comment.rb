# frozen_string_literal: true

class GithubComment < RedmineGitHosting.old_redmine? ? ActiveRecord::Base : ApplicationRecord
  ## Relations
  belongs_to :journal

  ## Validations
  validates :github_id,  presence: true
  validates :journal_id, presence: true, uniqueness: { scope: :github_id }
end
