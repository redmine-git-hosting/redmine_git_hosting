class RepositoryGitConfigKey < ActiveRecord::Base
  unloadable

  ## Attributes
  attr_accessible :key, :value

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, presence: true

  validates :key,           presence: true,
                            uniqueness: { case_sensitive: false, scope: :repository_id },
                            format:     { with: /^\A[a-zA-Z0-9]+\.[a-zA-Z0-9.]+\z/ }

  validates :value,         presence: true

  ## Callbacks
  after_commit ->(obj) { obj.create_or_update_config_key }, on: :create
  after_commit ->(obj) { obj.create_or_update_config_key }, on: :update
  after_commit ->(obj) { obj.delete_config_key },           on: :destroy


  protected


    def create_or_update_config_key
      options = {}
      options = {delete_git_config_key: self.key_change[0]} if self.key_changed?
      update_repository(options)
    end


    def delete_config_key
      options = {delete_git_config_key: self.key}
      update_repository(options)
    end


  private


    def update_repository(options)
      options = options.merge(message: "Rebuild Git config keys respository : '#{repository.gitolite_repository_name}'")
      UpdateRepository.new(repository, options).call
    end

end
