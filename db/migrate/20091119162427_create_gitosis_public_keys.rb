class CreateGitosisPublicKeys < ActiveRecord::Migration
  def self.up
    create_table :gitosis_public_keys do |t|
      t.column :title, :string
      t.column :identifier, :string
      t.column :key, :text
      t.column :active, :boolean, :default => true
      t.references :user
      t.timestamps
      
    end
  end

  def self.down
    drop_table :gitosis_public_keys
  end
end
