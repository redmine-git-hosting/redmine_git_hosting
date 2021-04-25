# frozen_string_literal: true

class RepositoryGitConfigKey::Option < RepositoryGitConfigKey
  validates :key, presence: true,
                  uniqueness: { case_sensitive: false, scope: %i[type repository_id] }
end
