class AddColumnsToRepositoryGitNotification < ActiveRecord::Migration

  def self.up
    add_column :repository_git_notifications, :prefix, :string
    add_column :repository_git_notifications, :sender_address, :string
  end

  def self.down
    remove_column :repository_git_notifications, :prefix
    remove_column :repository_git_notifications, :sender_address
  end

end
