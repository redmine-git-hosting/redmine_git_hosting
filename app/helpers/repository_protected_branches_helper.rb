module RepositoryProtectedBranchesHelper

  def protected_branch_available_users
    @project.member_principals.map(&:principal).select { |m| m.class.name == 'User' }.uniq.sort
  end

  def protected_branch_available_groups
    @project.member_principals.map(&:principal).select { |m| m.class.name == 'Group' }.uniq.sort
  end

end
