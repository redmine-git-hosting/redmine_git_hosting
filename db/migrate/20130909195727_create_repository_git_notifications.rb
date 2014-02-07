class CreateRepositoryGitNotifications < ActiveRecord::Migration

  def self.up
    create_table :repository_git_notifications do |t|
      t.column :repository_id, :integer
      t.column :include_list,  :text
      t.column :exclude_list,  :text
    end
  end

  def self.down
    drop_table :repository_git_notifications
  end

end
