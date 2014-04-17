class CreateRepositoryProtectedBranches < ActiveRecord::Migration
  def self.up
    create_table :repository_protected_branches do |t|
      t.column :repository_id, :integer, :null => false
      t.column :role_id,       :integer, :null => false
      t.column :path,          :string,  :null => false
      t.column :permissions,   :string,  :null => false
    end
  end

  def self.down
    drop_table :repository_protected_branches
  end
end
