class RepositoryGitConfigKey::GitConfig < RepositoryGitConfigKey

  VALID_CONFIG_KEY_REGEX = /\A[a-zA-Z0-9]+\.[a-zA-Z0-9.]+\z/

  validates :key, presence: true,
                  uniqueness: { case_sensitive: false, scope: [:type, :repository_id] },
                  format:     { with: VALID_CONFIG_KEY_REGEX }

end
