class RenameTableGitRepositoryExtras < ActiveRecord::Migration

  def self.up
    rename_table :git_repository_extras, :repository_git_extras
  end

  def self.down
    rename_table :repository_git_extras, :git_repository_extras
  end

end
