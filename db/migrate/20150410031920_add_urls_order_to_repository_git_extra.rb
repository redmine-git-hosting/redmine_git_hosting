class AddUrlsOrderToRepositoryGitExtra < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :urls_order, :text
  end

  def self.down
    remove_column :repository_git_extras, :urls_order
  end

end
