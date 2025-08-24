# frozen_string_literal: true

module RepositoryProtectedBranches
  class MemberManager
    attr_reader :protected_branch

    def initialize(protected_branch)
      @protected_branch = protected_branch
    end

    def current_user_ids
      protected_branch.users.map(&:id)
    end

    def current_group_ids
      protected_branch.groups.map(&:id)
    end

    def current_members
      protected_branch.protected_branches_members
    end

    def users_by_group_id(id)
      current_members.select { |pbm| pbm.principal.instance_of?(User) && pbm.inherited_by == id }
                     .map(&:principal)
    end

    def add_users(ids)
      create_user_member ids, current_user_ids
    end

    def add_groups(ids)
      create_group_member ids, current_group_ids do |group|
        ids = group.users.map(&:id)
        current_ids = users_by_group_id(group.id).map(&:id)
        create_user_member ids, current_ids, inherited_by: group.id, destroy: false
      end
    end

    def create_user_member(ids, current_ids, opts = {}, &block)
      create_member(ids, current_ids, User, **opts, &block)
    end

    def create_group_member(ids, current_ids, opts = {}, &block)
      create_member(ids, current_ids, Group, **opts, &block)
    end

    def add_user_from_group(user, group_id)
      ids = users_by_group_id(group_id).push(user).map(&:id)
      current_ids = users_by_group_id(group_id).map(&:id)
      create_user_member ids, current_ids, inherited_by: group_id, destroy: false
    end

    def remove_user_from_group(user, group_id)
      return unless users_by_group_id(group_id).include?(user)

      member = current_members.find_by protected_branch_id: protected_branch.id,
                                       principal_id: user.id,
                                       inherited_by: group_id
      member&.destroy!
    end

    def create_member(ids, current_ids, klass, destroy: true, inherited_by: nil, &block)
      ids = (ids || []).collect(&:to_i) - [0]
      new_ids = ids - current_ids
      new_ids.each do |id|
        object = klass.find_by id: id
        next if object.nil?

        current_members.create principal_id: object.id, inherited_by: inherited_by
        yield object if block
      end

      return unless destroy

      member_to_destroy = current_members.select { |m| m.principal.instance_of?(klass) && ids.exclude?(m.principal.id) }
      member_to_destroy.each(&:destroy) if member_to_destroy.any?
    end
  end
end
