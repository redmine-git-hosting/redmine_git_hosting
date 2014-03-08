class RepositoryGitConfigKey < ActiveRecord::Base
  unloadable

  belongs_to :repository

  validates_presence_of :key
  validates_presence_of :value

  validates_uniqueness_of :key, :scope => :repository_id

  validate :check_key_format

  after_commit ->(obj) { obj.create_or_update_config_key }, on: :create
  after_commit ->(obj) { obj.create_or_update_config_key }, on: :update
  after_commit ->(obj) { obj.delete_config_key },           on: :destroy


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


  private


  def check_key_format
    if !self.key.include?('.')
      errors.add(:key, :error_wrong_config_key_format)
      return false
    end
  end


  def update_repository(options)
    RedmineGitolite::GitHosting.logger.info { "Rebuild Git config keys respository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite({ :command => :update_repository, :object => repository.id, :options => options })
  end

end
