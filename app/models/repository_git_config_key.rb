class RepositoryGitConfigKey < ActiveRecord::Base
  unloadable

  belongs_to :repository

  validates_presence_of :key
  validates_presence_of :value

  validates_uniqueness_of :key, :scope => :repository_id

  after_update   :create_or_update_config_key
  before_destroy :delete_config_key


  private


  def create_or_update_config_key
    options = {}

    if self.key_changed?
      options = {:delete_git_config_key => self.key_change[0]}
    end

    update_repository(options)
  end


  def delete_config_key
    options = {:delete_git_config_key => self.key}
    update_repository(options)
  end


  def update_repository(options)
    RedmineGitolite::GitHosting.logger.info { "Rebuild Git config keys respository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository, :object => repository.id, :options => options })
  end

end
