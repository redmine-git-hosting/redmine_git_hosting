class RepositoryProtectedBrancheWrapped < RepositoryProtectedBranche
  serialize :user_list, Array
end

class MigrateProtectedBranchesUsers < ActiveRecord::Migration

  def self.up
    RepositoryProtectedBrancheWrapped.all.each do |protected_branch|
      users = protected_branch.user_list.map { |u| User.find_by_login(u) }.compact.uniq
      manager = RepositoryProtectedBranches::MemberManager.new(protected_branch)
      manager.add_users(users.map(&:id))
    end
    remove_column :repository_protected_branches, :user_list
  end

  def self.down
    add_column :repository_protected_branches, :user_list, :text, after: :permissions
    RepositoryProtectedBrancheWrapped.all.each do |protected_branch|
      users = protected_branch.users.map { |u| u.login }.compact.uniq
      protected_branch.user_list = users
      protected_branch.save!
    end
  end

end
