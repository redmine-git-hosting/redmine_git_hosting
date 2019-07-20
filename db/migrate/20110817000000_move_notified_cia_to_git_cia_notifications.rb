class MoveNotifiedCiaToGitCiaNotifications < ActiveRecord::Migration[4.2]
  def up
    drop_table :git_cia_notifications if table_exists?(:git_cia_notifications)

    create_table :git_cia_notifications do |t|
      t.column :repository_id, :integer
      t.column :scmid, :string
    end

    # Speed up searches
    add_index(:git_cia_notifications, :scmid)

    # Make sure uniqueness of the two columns, :scmid, :repository_id
    add_index(:git_cia_notifications, %i[scmid repository_id], unique: true)

    remove_column :changesets, :notified_cia if column_exists?(:changesets, :notified_cia)
  end

  def down
    drop_table :git_cia_notifications
  end

  def table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end

  def column_exists?(table_name, column_name)
    columns(table_name).any? { |c| c.name == column_name.to_s }
  end
end
