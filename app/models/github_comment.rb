# frozen_string_literal: true

class GithubComment < ActiveRecord::Base
  ## Relations
  belongs_to :journal

  ## Validations
  validates :github_id,  presence: true
  validates :journal_id, uniqueness: { scope: :github_id }
end
