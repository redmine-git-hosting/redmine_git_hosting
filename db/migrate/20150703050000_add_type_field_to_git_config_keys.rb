class AddTypeFieldToGitConfigKeys < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_git_config_keys, :type, :string
  end
end
