class AddColumnsToRepositoryGitNotification < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_git_notifications, :prefix, :string
    add_column :repository_git_notifications, :sender_address, :string
  end
end
