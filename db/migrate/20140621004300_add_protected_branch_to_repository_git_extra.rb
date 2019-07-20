class AddProtectedBranchToRepositoryGitExtra < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_git_extras, :protected_branch, :boolean, default: false, after: :default_branch
  end
end
