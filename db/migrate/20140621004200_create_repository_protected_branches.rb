class CreateRepositoryProtectedBranches < ActiveRecord::Migration

  def self.up
    create_table :repository_protected_branches do |t|
      t.column :repository_id, :integer
      t.column :path,          :string
      t.column :permissions,   :string
      t.column :user_list,     :text
      t.column :position,      :integer
    end

    add_index :repository_protected_branches, :repository_id
  end

  def self.down
    drop_table :repository_protected_branches
  end

end
