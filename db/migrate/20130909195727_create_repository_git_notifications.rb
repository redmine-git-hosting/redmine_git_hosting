class CreateRepositoryGitNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :repository_git_notifications do |t|
      t.column :repository_id, :integer
      t.column :include_list,  :text
      t.column :exclude_list,  :text
    end
  end
end
