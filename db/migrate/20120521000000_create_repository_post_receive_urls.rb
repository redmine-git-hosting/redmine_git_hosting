class CreateRepositoryPostReceiveUrls < ActiveRecord::Migration
  def self.up
    create_table :repository_post_receive_urls do |t|
      t.column :project_id, :integer
      t.column :active, :integer, :default => 1
      t.column :url, :string
      t.references :project
      t.timestamps
    end
  end

  def self.down
    drop_table :repository_post_receive_urls
  end
end
