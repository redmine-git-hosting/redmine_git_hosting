class EnforceModelsConstraints < ActiveRecord::Migration

  def self.up
    change_column :git_caches, :command_output, :binary, limit: 16777216
    remove_column :repository_mirrors, :created_at
    remove_column :repository_mirrors, :updated_at
    remove_column :repository_post_receive_urls, :created_at
    remove_column :repository_post_receive_urls, :updated_at
  end

end
