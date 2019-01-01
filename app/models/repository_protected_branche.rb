class RepositoryProtectedBranche < ActiveRecord::Base
  include Redmine::SafeAttributes
  VALID_PERMS  = ['RW+', 'RW', 'R', '-'].freeze
  DEFAULT_PERM = 'RW+'.freeze

  acts_as_positioned

  ## Attributes
  safe_attributes 'path', 'permissions', 'position'

  ## Relations
  belongs_to :repository
  has_many   :protected_branches_members, foreign_key: :protected_branch_id, dependent: :destroy
  has_many   :members, through: :protected_branches_members, source: :principal

  ## Validations
  validates :repository_id, presence: true
  validates :path,          presence: true, uniqueness: { scope: %i[permissions repository_id] }
  validates :permissions,   presence: true, inclusion: { in: VALID_PERMS }

  ## Scopes
  default_scope { order(position: :asc) }

  class << self
    def clone_from(parent)
      parent = find_by(id: parent) unless parent.is_a? RepositoryProtectedBranche
      copy = new
      copy.attributes = parent.attributes
      copy.repository = parent.repository
      copy
    end
  end

  # Accessors
  #
  def users
    members.select { |m| m.class.name == 'User' }.uniq
  end

  def groups
    members.select { |m| m.class.name == 'Group' }.uniq
  end

  def allowed_users
    users.map(&:gitolite_identifier).sort
  end
end
