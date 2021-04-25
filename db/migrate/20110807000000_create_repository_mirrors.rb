# frozen_string_literal: true

class CreateRepositoryMirrors < ActiveRecord::Migration[4.2]
  def change
    create_table :repository_mirrors do |t|
      t.references :project, type: :integer
      t.column :active, :integer, default: 1
      t.column :url, :string
      t.timestamps
    end
  end
end
