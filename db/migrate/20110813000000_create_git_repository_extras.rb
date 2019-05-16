class CreateGitRepositoryExtras < ActiveRecord::Migration[4.2]
  def up
    drop_table :git_repository_extras if table_exists?(:git_repository_extras)

    create_table :git_repository_extras do |t|
      t.column :repository_id, :integer
      t.column :git_daemon,    :integer, default: 1
      t.column :git_http,      :integer, default: 1
      t.column :notify_cia,    :integer, default: 0
      t.column :key,           :string
    end

    drop_table :git_hook_keys if table_exists?('git_hook_keys')
    remove_column :repositories, :git_daemon if column_exists?(:repositories, :git_daemon)
    remove_column :repositories, :git_http if column_exists?(:repositories, :git_http)
  end

  def down
    drop_table :git_repository_extras
  end

  def table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end

  def column_exists?(table_name, column_name)
    columns(table_name).any? { |c| c.name == column_name.to_s }
  end
end
