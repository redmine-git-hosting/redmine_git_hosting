class AddUrlsOrderToRepositoryGitExtra < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_git_extras, :urls_order, :text
  end
end
