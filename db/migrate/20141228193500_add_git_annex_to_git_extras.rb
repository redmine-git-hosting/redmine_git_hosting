class AddGitAnnexToGitExtras < ActiveRecord::Migration

  def self.up
    add_column :repository_git_extras, :git_annex, :boolean, default: false, after: :git_notify
  end

  def self.down
    remove_column :repository_git_extras, :git_annex
  end

end
