class RepositoryProtectedBranche < ActiveRecord::Base
  unloadable

  VALID_PERMS  = ['RW+', 'RW', 'R', '-']
  DEFAULT_PERM = 'RW+'

  acts_as_list

  ## Attributes
  attr_accessible :path, :permissions, :position, :user_ids, :group_ids

  ## Relations
  belongs_to :repository
  has_many   :protected_branches_members, foreign_key: :protected_branch_id, dependent: :destroy
  has_many   :members, through: :protected_branches_members, source: :principal

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


  # Accessors
  #
  def users
    members.select { |m| m.class.name == 'User' }.uniq
  end


  def groups
    members.select { |m| m.class.name == 'Group' }
  end


  def allowed_users
    users.map { |u| u.gitolite_identifier }.sort
  end


  # Mass assignment
  #
  def user_ids=(ids)
    current_ids = users.map(&:id)
    create_member(ids, current_ids, 'User')
  end


  def group_ids=(ids)
    current_ids = groups.map(&:id)
    create_member(ids, current_ids, 'Group') do |group|
      ids = group.users.map(&:id)
      current_ids = users_by_group_id(group.id).map(&:id)
      create_member(ids, current_ids, 'User', inherited_by: group.id, destroy: false)
    end
  end


  # Triggered by Group callbacks
  #
  def add_user_member(user, group)
    ids = users_by_group_id(group.id).push(user).map(&:id)
    current_ids = users_by_group_id(group.id).map(&:id)
    create_member(ids, current_ids, 'User', inherited_by: group.id, destroy: false)
  end


  def remove_user_member(user, group)
    return unless users_by_group_id(group.id).include?(user)
    member = protected_branches_members.find_by_protected_branch_id_and_principal_id_and_inherited_by(id, user.id, group.id)
    member.destroy! unless member.nil?
  end


  private


    def users_by_group_id(id)
      protected_branches_members.select { |pbm| pbm.principal.class.name == 'User' && pbm.inherited_by == id }.map(&:principal)
    end


    def create_member(ids, current_ids, klass, destroy: true, inherited_by: nil, &block)
      ids = (ids || []).collect(&:to_i) - [0]
      new_ids = ids - current_ids

      new_ids.each do |id|
        object = klass.constantize.find_by_id(id)
        next if object.nil?
        protected_branches_members.create(principal_id: object.id, inherited_by: inherited_by)
        yield object if block_given?
      end

      if destroy
        member_to_destroy = protected_branches_members.select { |m| m.principal.class.name == klass && !ids.include?(m.principal.id) }
        member_to_destroy.each(&:destroy) if member_to_destroy.any?
      end
    end

end
