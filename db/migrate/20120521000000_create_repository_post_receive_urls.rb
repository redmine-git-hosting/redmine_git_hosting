class CreateRepositoryPostReceiveUrls < ActiveRecord::Migration[4.2]
  def change
    create_table :repository_post_receive_urls do |t|
      t.references :project, type: :integer
      t.column :active, :integer, default: 1
      t.column :url, :string
      t.timestamps
    end
  end
end
