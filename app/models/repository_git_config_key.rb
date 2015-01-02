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
  after_save :check_if_key_changed

  ## Virtual attribute
  attr_accessor :key_has_changed
  attr_accessor :old_key


  def key_has_changed?
    key_has_changed
  end


  private


    def check_if_key_changed
      if self.key_changed?
        self.key_has_changed = true
        self.old_key         = self.key_change[0]
      else
        self.key_has_changed = false
        self.old_key         = ''
      end
    end

end
