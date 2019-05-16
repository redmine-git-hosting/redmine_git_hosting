class CreateGithubIssues < ActiveRecord::Migration[4.2]
  def change
    create_table :github_issues do |t|
      t.column :github_id, :integer, null: false
      t.column :issue_id,  :integer, null: false
    end
  end
end
