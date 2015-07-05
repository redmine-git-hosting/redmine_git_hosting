class RenameGitConfigKeysIndex < ActiveRecord::Migration

  def self.up
    remove_index :repository_git_config_keys, [:key, :repository_id]
    add_index :repository_git_config_keys, [:key, :type, :repository_id], unique: true, name: :unique_key_name
  end

  def self.down
    remove_index :repository_git_config_keys, name: :unique_key_name
    add_index :repository_git_config_keys, [:key, :repository_id], unique: true
  end

end
