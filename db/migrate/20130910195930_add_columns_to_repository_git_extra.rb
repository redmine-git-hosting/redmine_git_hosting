class AddColumnsToRepositoryGitExtra < ActiveRecord::Migration

  def self.up
    unless RepositoryGitExtra.column_names.include? 'git_notify'
      add_column :repository_git_extras, :git_notify, :integer, default: 0, after: :git_http
    end
  end

  def self.down
    remove_column :repository_git_extras, :git_notify
  end

end
