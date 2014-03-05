class AddDefaultBranchToRepositoryGitExtra < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :default_branch, :string, :null => false, :after => :git_notify
  end

  def self.down
    remove_column :repository_git_extras, :default_branch
  end
end
