class RemoveNotifyCia < ActiveRecord::Migration[4.2]
  def up
    drop_table :git_cia_notifications
    remove_column :repository_git_extras, :notify_cia
  end

  def down
    create_table :git_cia_notifications do |t|
      t.column :repository_id, :integer
      t.column :scmid, :string
    end
  end
end
