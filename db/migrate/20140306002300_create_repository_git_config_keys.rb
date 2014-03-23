class CreateRepositoryGitConfigKeys < ActiveRecord::Migration

  def self.up
    create_table :repository_git_config_keys do |t|
      t.column :repository_id, :integer
      t.column :key,   :string
      t.column :value, :string
    end
  end

  def self.down
    drop_table :repository_git_config_keys
  end

end
