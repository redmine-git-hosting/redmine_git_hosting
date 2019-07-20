class CreateRepositoryMirrors < ActiveRecord::Migration[4.2]
  def change
    create_table :repository_mirrors do |t|
      t.column :project_id, :integer
      t.column :active, :integer, default: 1
      t.column :url, :string
      t.references :project
      t.timestamps
    end
  end
end
