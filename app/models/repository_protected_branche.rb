class RepositoryProtectedBranche < ActiveRecord::Base
  unloadable

  VALID_PERMS  = [ "RW+", "RW", "R", '-' ]
  DEFAULT_PERM = "RW+"

  attr_accessible :role_id, :path, :permissions

  ## Relations
  belongs_to :repository
  belongs_to :role

  ## Validations
  validates :repository_id, :presence => true
  validates :role_id,       :presence => true
  validates :path,          :presence => true
  validates :permissions,   :presence => true, :inclusion => { :in => VALID_PERMS }

  ## Callbacks
  after_commit ->(obj) { obj.update_permissions }, :on => :create
  after_commit ->(obj) { obj.update_permissions }, :on => :update
  after_commit ->(obj) { obj.update_permissions }, :on => :destroy


  def self.clone_from(parent)
    parent = find_by_id(parent) unless parent.kind_of? RepositoryProtectedBranche
    copy = self.new
    copy.attributes = parent.attributes

    copy
  end


  protected


  def update_permissions
    RedmineGitolite::GitHosting.logger.info { "Update branch permissions for repository : '#{repository.gitolite_repository_name}'" }
    RedmineGitolite::GitHosting.resync_gitolite(:update_repository, repository.id)
  end

end
