class CreateGithubComments < ActiveRecord::Migration[4.2]
  def change
    create_table :github_comments do |t|
      t.column :github_id,  :integer, null: false
      t.column :journal_id, :integer, null: false
    end
  end
end
