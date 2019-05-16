class CreateProtectedBranchesMembers < ActiveRecord::Migration[4.2]
  def change
    create_table :protected_branches_members do |t|
      t.column :protected_branch_id, :integer
      t.column :principal_id,        :integer
      t.column :inherited_by,        :integer
    end

    add_index :protected_branches_members,
              %i[protected_branch_id principal_id inherited_by],
              unique: true,
              name: 'unique_protected_branch_member'
  end
end
