module RepositoryProtectedBranchesHelper

  def protected_branch_available_users
    @project.member_principals.map(&:user).uniq.sort
  end

end
