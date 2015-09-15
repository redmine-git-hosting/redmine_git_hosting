class CreateGithubIssues < ActiveRecord::Migration

  def self.up
    create_table :github_issues do |t|
      t.column :github_id, :integer, null: false
      t.column :issue_id,  :integer, null: false
    end
  end

  def self.down
    drop_table :github_issues
  end

end
