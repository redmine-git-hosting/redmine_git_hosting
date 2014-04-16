class AddDefaultBranchToRepositoryGitExtra < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :default_branch, :string, :after => :git_notify

    RepositoryGitExtra.reset_column_information
    RepositoryGitExtra.all.each do |extra|
      extra.update_attribute(:default_branch, 'master')
    end

    change_column :repository_git_extras, :default_branch, :string, :null => false
  end

  def self.down
    remove_column :repository_git_extras, :default_branch
  end
end
