class RenameTableGitRepositoryExtras < ActiveRecord::Migration[4.2]
  def change
    rename_table :git_repository_extras, :repository_git_extras
  end
end
