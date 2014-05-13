class RepositoryGitConfigKey < ActiveRecord::Base
  unloadable

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, :presence => true

  validates :key,           :presence => true,
                            :uniqueness => { :case_sensitive => false, :scope => :repository_id }

  validates :value,         :presence => true

  validate :check_key_format

  ## Callbacks
  after_commit ->(obj) { obj.create_or_update_config_key }, on: :create
  after_commit ->(obj) { obj.create_or_update_config_key }, on: :update
  after_commit ->(obj) { obj.delete_config_key },           on: :destroy


  protected


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
