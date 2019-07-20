class CreateRepositoryPostReceiveUrls < ActiveRecord::Migration[4.2]
  def change
    create_table :repository_post_receive_urls do |t|
      t.column :project_id, :integer
      t.column :active, :integer, default: 1
      t.column :url, :string
      t.references :project
      t.timestamps
    end
  end
end
