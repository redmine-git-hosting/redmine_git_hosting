class AddTypeFieldToGitConfigKeys < ActiveRecord::Migration

  def self.up
    add_column :repository_git_config_keys, :type, :string
  end

  def self.down
    remove_column :repository_git_config_keys, :type
  end

end
