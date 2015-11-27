class ShrinkGitNotifications < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :notification_sender, :string
    add_column :repository_git_extras, :notification_prefix, :string
    drop_table :repository_git_notifications
  end

  def self.down
    remove_column :repository_git_extras, :notification_sender
    remove_column :repository_git_extras, :notification_prefix

    create_table :repository_git_notifications do |t|
      t.integer :repository_id
      t.text    :include_list
      t.text    :exclude_list
      t.string  :prefix
      t.string  :sender_address
    end
  end

end
