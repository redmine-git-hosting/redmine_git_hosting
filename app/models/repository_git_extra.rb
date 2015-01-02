class RepositoryGitExtra < ActiveRecord::Base
  unloadable

  SMART_HTTP_OPTIONS = [
    [l(:label_disabled), "0"],
    [l(:label_http_only), "3"],
    [l(:label_https_only), "1"],
    [l(:label_https_and_http), "2"]
  ]

  DISABLED = 0
  HTTP     = 1
  HTTPS    = 2
  BOTH     = 3

  ## Attributes
  attr_accessible :git_http, :git_daemon, :git_notify, :git_annex, :default_branch, :protected_branch, :key

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id,  presence: true, uniqueness: true
  validates :git_http,       presence: true, numericality: { only_integer: true }, inclusion: { in: [DISABLED, HTTP, HTTPS, BOTH] }
  validates :default_branch, presence: true
  validates :key,            presence: true

  ## Callbacks
  after_save :check_if_default_branch_changed

  ## Virtual attribute
  attr_accessor :default_branch_has_changed


  # Syntaxic sugar
  def default_branch_has_changed?
    default_branch_has_changed
  end


  private


    # This is Rails method : <attribute>_changed?
    # However, the value is cleared before passing the object to the controller.
    # We need to save it in virtual attribute to trigger Gitolite resync if changed.
    #
    def check_if_default_branch_changed
      if default_branch_changed?
        self.default_branch_has_changed = true
      else
        self.default_branch_has_changed = false
      end
    end

end
