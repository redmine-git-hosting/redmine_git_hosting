class AddGitAnnexToGitExtras < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_git_extras, :git_annex, :boolean, default: false, after: :git_notify
  end
end
