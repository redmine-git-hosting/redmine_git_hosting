class CreateGitolitePublicKeys < ActiveRecord::Migration[4.2]
  def change
    create_table :gitolite_public_keys do |t|
      t.column :title, :string
      t.column :identifier, :string
      t.column :key, :text
      t.column :active, :integer, default: 1
      t.references :user
      t.timestamps
    end
  end
end
