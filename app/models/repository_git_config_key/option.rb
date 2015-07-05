class RepositoryGitConfigKey::Option < RepositoryGitConfigKey
  unloadable

  validates :key, presence: true,
                  uniqueness: { case_sensitive: false, scope: [:type, :repository_id] }

end
