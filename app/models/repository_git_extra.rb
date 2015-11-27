class RepositoryGitExtra < ActiveRecord::Base

  SMART_HTTP_OPTIONS = [
    [l(:label_disabled), '0'],
    [l(:label_http_only), '3'],
    [l(:label_https_only), '1'],
    [l(:label_https_and_http), '2']
  ]

  DISABLED = 0
  HTTP     = 3
  HTTPS    = 1
  BOTH     = 2

  ALLOWED_URLS = %w[ssh http https go git git_annex]

  URLS_ICONS = {
    go:        { label: 'Go',       icon: 'fa-google' },
    http:      { label: 'HTTP',     icon: 'fa-external-link' },
    https:     { label: 'HTTPS',    icon: 'fa-external-link' },
    ssh:       { label: 'SSH',      icon: 'fa-shield' },
    git:       { label: 'Git',      icon: 'fa-git' },
    git_annex: { label: 'GitAnnex', icon: 'fa-git' }
  }

  ## Attributes
  attr_accessible :git_http, :git_daemon, :git_notify, :git_annex, :default_branch, :protected_branch,
                  :public_repo, :key, :urls_order, :notification_sender, :notification_prefix

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id,       presence: true, uniqueness: true
  validates :git_http,            presence: true, numericality: { only_integer: true }, inclusion: { in: [DISABLED, HTTP, HTTPS, BOTH] }
  validates :default_branch,      presence: true
  validates :key,                 presence: true
  validates :notification_sender, format: { with: RedmineGitHosting::Validators::EMAIL_REGEX, allow_blank: true }

  validate :validate_urls_order

  ## Serializations
  serialize :urls_order, Array

  ## Callbacks
  before_save :check_urls_order_consistency
  after_save  :check_if_default_branch_changed

  ## Virtual attribute
  attr_accessor :default_branch_has_changed


  # Syntaxic sugar
  def default_branch_has_changed?
    default_branch_has_changed
  end


  private


    def validate_urls_order
      urls_order.each do |url|
        errors.add(:urls_order, :invalid) unless ALLOWED_URLS.include?(url)
      end
    end


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


    def check_urls_order_consistency
      check_ssh_url
      check_git_http_urls
      # Add go url only for existing record to avoid chicken/egg issue
      check_go_url unless new_record?
      check_git_url
      check_git_annex_url
    end


    # SSH url should always be present in urls_order Array
    #
    def check_ssh_url
      add_url('ssh')
    end


    def check_git_http_urls
      case git_http
      when HTTP
        add_url('http')
        remove_url('https')
      when HTTPS
        add_url('https')
        remove_url('http')
      when BOTH
        add_url('http')
        add_url('https')
      else
        remove_url('http')
        remove_url('https')
      end
    end


    def check_go_url
      repository.go_access_available? ? add_url('go') : remove_url('go')
    end


    def check_git_annex_url
      git_annex? ? add_url('git_annex') : remove_url('git_annex')
    end


    def check_git_url
      git_daemon? ? add_url('git') : remove_url('git')
    end


    def remove_url(url)
      self.urls_order.delete(url)
    end


    def add_url(url)
      self.urls_order.push(url).uniq!
    end

end
