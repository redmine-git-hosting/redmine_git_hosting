# frozen_string_literal: true

class GithubComment < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  ## Relations
  belongs_to :journal

  ## Validations
  validates :github_id,  presence: true
  validates :journal_id, presence: true, uniqueness: { scope: :github_id }
end
