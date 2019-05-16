class RenameGitConfigKeysIndex < ActiveRecord::Migration[4.2]
  def up
    remove_index :repository_git_config_keys, %i[key repository_id]
    add_index :repository_git_config_keys, %i[key type repository_id], unique: true, name: :unique_key_name
  end

  def down
    remove_index :repository_git_config_keys, name: :unique_key_name
    add_index :repository_git_config_keys, %i[key repository_id], unique: true
  end
end
