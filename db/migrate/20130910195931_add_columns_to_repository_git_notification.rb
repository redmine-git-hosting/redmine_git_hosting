class AddColumnsToRepositoryGitNotification < ActiveRecord::Migration

  def self.up
    unless RepositoryGitNotification.column_names.include? "prefix"
      add_column :repository_git_notifications, :prefix, :string
    end

    unless RepositoryGitNotification.column_names.include? "sender_address"
      add_column :repository_git_notifications, :sender_address, :string
    end
  end

  def self.down
    remove_column :repository_git_notifications, :prefix
    remove_column :repository_git_notifications, :sender_address
  end
end
