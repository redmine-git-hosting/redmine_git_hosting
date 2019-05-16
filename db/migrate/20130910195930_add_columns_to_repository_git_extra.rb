class AddColumnsToRepositoryGitExtra < ActiveRecord::Migration[4.2]
  def up
    return if RepositoryGitExtra.column_names.include? 'git_notify'

    add_column :repository_git_extras, :git_notify, :integer, default: 0, after: :git_http
  end

  def down
    remove_column :repository_git_extras, :git_notify
  end
end
