class RepositoryProtectedBranche < ActiveRecord::Base
  unloadable

  VALID_PERMS  = ['RW+', 'RW', 'R', '-']
  DEFAULT_PERM = 'RW+'

  acts_as_list

  ## Attributes
  attr_accessible :path, :permissions, :position, :user_ids

  ## Relations
  belongs_to :repository
  has_many   :protected_branches_users, foreign_key: :protected_branch_id, dependent: :destroy
  has_many   :users, through: :protected_branches_users

  ## Validations
  validates :repository_id, presence: true
  validates :path,          presence: true, uniqueness: { scope: [:permissions, :repository_id] }
  validates :permissions,   presence: true, inclusion: { in: VALID_PERMS }

  ## Scopes
  default_scope { order('position ASC') }


  class << self

    def clone_from(parent)
      parent = find_by_id(parent) unless parent.kind_of? RepositoryProtectedBranche
      copy = self.new
      copy.attributes = parent.attributes
      copy.repository = parent.repository
      copy
    end

  end


  def allowed_users
    users.map { |u| u.gitolite_identifier }.sort
  end

end
