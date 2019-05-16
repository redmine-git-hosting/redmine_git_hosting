class AddPublicRepoToRepositoryGitExtra < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_git_extras, :public_repo, :boolean, default: false, after: :protected_branch
  end
end
