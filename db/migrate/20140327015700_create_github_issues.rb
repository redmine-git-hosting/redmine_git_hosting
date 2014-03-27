class CreateGithubIssues < ActiveRecord::Migration

  def self.up
    create_table :github_issues, :id => false do |t|
      t.column :github_id, :integer
      t.column :issue_id,  :integer
    end
  end

  def self.down
    drop_table :github_issues
  end

end
