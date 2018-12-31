class RepositoryGitConfigKey < ActiveRecord::Base
  include Redmine::SafeAttributes

  ## Attributes
  safe_attributes 'type', 'key', 'value'

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, presence: true
  validates :type,          presence: true, inclusion: { in: ['RepositoryGitConfigKey::GitConfig', 'RepositoryGitConfigKey::Option'] }
  validates :value,         presence: true

  ## Callbacks
  after_save :check_if_key_changed

  ## Virtual attribute
  attr_accessor :key_has_changed
  attr_accessor :old_key

  # Syntaxic sugar
  def key_has_changed?
    key_has_changed
  end

  private

  # This is Rails method : <attribute>_changed?
  # However, the value is cleared before passing the object to the controller.
  # We need to save it in virtual attribute to trigger Gitolite resync if changed.
  #
  def check_if_key_changed
    if key_changed?
      self.key_has_changed = true
      self.old_key         = key_change[0]
    else
      self.key_has_changed = false
      self.old_key         = ''
    end
  end
end
