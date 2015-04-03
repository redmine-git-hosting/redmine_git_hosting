class RepositoryProtectedBranche < ActiveRecord::Base
  unloadable

  VALID_PERMS  = ['RW+', 'RW']
  DEFAULT_PERM = 'RW+'

  acts_as_list

  ## Attributes
  attr_accessible :path, :permissions, :position, :user_list

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, presence: true
  validates :path,          presence: true, uniqueness: { scope: [:permissions, :repository_id] }
  validates :permissions,   presence: true, inclusion: { in: VALID_PERMS }
  validates :user_list,     presence: true

  ## Serializations
  serialize :user_list, Array

  ## Callbacks
  before_validation :remove_blank_items

  ## Scopes
  default_scope { order('position ASC') }

  ## Delegation
  delegate :project, to: :repository


  class << self

    def clone_from(parent)
      parent = find_by_id(parent) unless parent.kind_of? RepositoryProtectedBranche
      copy = self.new
      copy.attributes = parent.attributes
      copy.repository = parent.repository
      copy
    end

  end


  def available_users
    project.member_principals.map(&:user).compact.uniq.map{ |u| u.login }.sort
  end


  def allowed_users
    user_list.map{|u| User.find_by_login(u).gitolite_identifier}.sort
  end


  private


    def remove_blank_items
      self.user_list = user_list.select{|u| !u.blank?} rescue []
    end

end
