class AddProtectedBranchToRepositoryGitExtra < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :protected_branch, :boolean, default: false, after: :default_branch
  end

  def self.down
    remove_column :repository_git_extras, :protected_branch
  end

end
