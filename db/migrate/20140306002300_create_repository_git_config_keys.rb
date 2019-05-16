class CreateRepositoryGitConfigKeys < ActiveRecord::Migration[4.2]
  def change
    create_table :repository_git_config_keys do |t|
      t.column :repository_id, :integer
      t.column :key,   :string
      t.column :value, :string
    end
  end
end
