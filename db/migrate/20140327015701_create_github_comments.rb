class CreateGithubComments < ActiveRecord::Migration

  def self.up
    create_table :github_comments do |t|
      t.column :github_id,  :integer, null: false
      t.column :journal_id, :integer, null: false
    end
  end

  def self.down
    drop_table :github_comments
  end

end
