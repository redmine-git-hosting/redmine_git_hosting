class ExtendChangesetsNotifiedCia < ActiveRecord::Migration[4.2]
  def up
    add_column :changesets, :notified_cia, :integer, default: 0
  end

  def down
    # Deal with fact that one of next migrations doesn't restore :notified_cia
    remove_column :changesets, :notified_cia if column_exists?(:changesets, :notified_cia)
  end

  def column_exists?(table_name, column_name)
    columns(table_name).any? { |c| c.name == column_name.to_s }
  end
end
