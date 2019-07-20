class RepositoryGitExtra < ActiveRecord::Base
  include Redmine::SafeAttributes

  SMART_HTTP_OPTIONS = [[l(:label_disabled), '0'],
                        [l(:label_http_only), '3'],
                        [l(:label_https_only), '1'],
                        [l(:label_https_and_http), '2']].freeze

  ALLOWED_URLS = %w[ssh http https go git git_annex].freeze

  URLS_ICONS = { go: { label: 'Go', icon: 'fab_google' },
                 http: { label: 'HTTP', icon: 'fas_external-link-alt' },
                 https: { label: 'HTTPS', icon: 'fas_external-link-alt' },
                 ssh: { label: 'SSH', icon: 'fas_shield-alt' },
                 git: { label: 'Git', icon: 'fab_git' },
                 git_annex: { label: 'GitAnnex', icon: 'fab_git' } }.freeze

  ## Attributes
  safe_attributes 'git_http', 'git_https', 'git_ssh', 'git_go', 'git_daemon', 'git_notify', 'git_annex', 'default_branch',
                  'protected_branch', 'public_repo', 'key', 'urls_order', 'notification_sender', 'notification_prefix'

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id,       presence: true, uniqueness: true
  validates :default_branch,      presence: true
  validates :key,                 presence: true
  validates :notification_sender, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

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
    self.default_branch_has_changed = if default_branch_changed?
                                        true
                                      else
                                        false
                                      end
  end

  def check_urls_order_consistency
    check_ssh_url
    check_git_http_urls
    check_go_url
    check_git_url
    check_git_annex_url
  end

  def check_ssh_url
    git_ssh? ? add_url('ssh') : remove_url('ssh')
  end

  def check_git_http_urls
    if git_http? && git_https?
      add_url('http')
      add_url('https')
    elsif git_http?
      add_url('http')
      remove_url('https')
    elsif git_https?
      add_url('https')
      remove_url('http')
    else
      remove_url('http')
      remove_url('https')
    end
  end

  def check_go_url
    git_go? ? add_url('go') : remove_url('go')
  end

  def check_git_annex_url
    git_annex? ? add_url('git_annex') : remove_url('git_annex')
  end

  def check_git_url
    git_daemon? ? add_url('git') : remove_url('git')
  end

  def remove_url(url)
    urls_order.delete(url)
  end

  def add_url(url)
    urls_order.push(url).uniq!
  end
end
