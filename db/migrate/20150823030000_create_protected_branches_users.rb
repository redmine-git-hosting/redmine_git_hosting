class CreateProtectedBranchesUsers < ActiveRecord::Migration

  def self.up
    create_table :protected_branches_users do |t|
      t.column :protected_branch_id, :integer
      t.column :user_id,             :integer
    end

    add_index :protected_branches_users, [:protected_branch_id, :user_id], unique: true, name: 'unique__protected_branch_id_user_id'
  end

  def self.down
    drop_table :protected_branches_users
  end

end
