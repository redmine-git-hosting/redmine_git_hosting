class RepositoryGitExtra < ActiveRecord::Base
  unloadable

  DISABLED = 0
  HTTP     = 1
  HTTPS    = 2
  BOTH     = 3

  ## Attributes
  attr_accessible :git_http, :git_daemon, :git_notify, :default_branch, :protected_branch

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id,    presence: true, uniqueness: true

  validates :git_http,         presence: true,
                               numericality: { only_integer: true },
                               inclusion:    { in: [DISABLED, HTTP, HTTPS, BOTH] }

  validates :default_branch,   presence: true
  validates :key,              presence: true

  validates :git_daemon,
  validates :git_notify,
  validates :protected_branch,

  validates_associated :repository

  ## Callbacks
  after_initialize :set_values


  private


    def set_values
      if self.repository.nil? && self.key.nil?
        self.key = (0...64+rand(64) ).map{65.+(rand(25)).chr}.join
      end
    end

end
