# frozen_string_literal: true

class GithubIssue < ActiveRecord::Base
  ## Relations
  belongs_to :issue

  ## Validations
  validates :github_id, presence: true
  validates :issue_id, uniqueness: { scope: :github_id }
end
