class AddPublicRepoToRepositoryGitExtra < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :public_repo, :boolean, default: false, after: :protected_branch
  end

  def self.down
    remove_column :repository_git_extras, :public_repo
  end

end
