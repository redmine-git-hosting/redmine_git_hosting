class EnforceModelsConstraints < ActiveRecord::Migration[4.2]
  def up
    change_column :git_caches, :command_output, :binary, limit: 16_777_216
    remove_column :repository_mirrors, :created_at
    remove_column :repository_mirrors, :updated_at
    remove_column :repository_post_receive_urls, :created_at
    remove_column :repository_post_receive_urls, :updated_at
  end

  def down
    add_column :repository_mirrors, :created_at, :datetime
    add_column :repository_mirrors, :updated_at, :datetime
    add_column :repository_post_receive_urls, :created_at, :datetime
    add_column :repository_post_receive_urls, :updated_at, :datetime
  end
end
