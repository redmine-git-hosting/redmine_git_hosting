class RepositoryProtectedBranche < ActiveRecord::Base
  unloadable

  VALID_PERMS  = [ "RW+", "RW" ]
  DEFAULT_PERM = "RW+"

  acts_as_list

  ## Attributes
  attr_accessible :path, :permissions, :position, :user_list

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, :presence => true
  validates :path,          :presence => true, :uniqueness => { :scope => :permissions }
  validates :permissions,   :presence => true, :inclusion => { :in => VALID_PERMS }
  validates :user_list,     :presence => true

  ## Serializations
  serialize :user_list, Array

  ## Callbacks
  before_validation :remove_blank_items

  after_commit ->(obj) { obj.update_permissions }, :on => :create
  after_commit ->(obj) { obj.update_permissions }, :on => :update
  after_commit ->(obj) { obj.update_permissions }, :on => :destroy

  ## Scopes
  default_scope order('position ASC')


  def self.clone_from(parent)
    parent = find_by_id(parent) unless parent.kind_of? RepositoryProtectedBranche
    copy = self.new
    copy.attributes = parent.attributes
    copy.repository = parent.repository

    copy
  end


  def available_users
    repository.project.member_principals.map(&:user).compact.uniq.map{ |user| user.login }.sort
  end


  def allowed_users
    self.user_list.map{ |user| User.find_by_login(user).gitolite_identifier }.sort
  end


  protected


  def update_permissions
    RedmineGitolite::GitHosting.logger.info { "Update branch permissions for repository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite(:update_repository, repository.id)
  end


  private


  def remove_blank_items
    self.user_list = user_list.select{ |user| !user.blank? } rescue []
  end

end
