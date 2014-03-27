class CreateGithubComments < ActiveRecord::Migration

  def self.up
    create_table :github_comments, :id => false do |t|
      t.column :github_id,  :integer
      t.column :journal_id, :integer
    end
  end

  def self.down
    drop_table :github_comments
  end

end
