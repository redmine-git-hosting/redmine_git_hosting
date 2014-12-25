require_dependency 'redmine/scm/adapters/xitolite_adapter'

class Repository::Xitolite < Repository::Git
  unloadable

  include Gitolitable
  include GitolitableCache
  include GitolitablePaths
  include GitolitableUrls
  include GitolitableNotifications

  # Relations
  has_one  :git_extra,              dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitExtra'
  has_one  :git_notification,       dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitNotification'
  has_many :mirrors,                dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryMirror'
  has_many :post_receive_urls,      dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryPostReceiveUrl'
  has_many :deployment_credentials, dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryDeploymentCredential'
  has_many :git_config_keys,        dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryGitConfigKey'
  has_many :protected_branches,     dependent: :destroy, foreign_key: 'repository_id', class_name: 'RepositoryProtectedBranche'

  class << self

    def scm_adapter_class
      Redmine::Scm::Adapters::XitoliteAdapter
    end

    def scm_name
      'Gitolite'
    end

  end


  def sti_name
    'Repository::Xitolite'
  end

end
