class AddRepositoryMirrorFields < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_mirrors, :push_mode, :integer, default: 0
    add_column :repository_mirrors, :include_all_branches, :boolean, default: false
    add_column :repository_mirrors, :include_all_tags, :boolean, default: false
    add_column :repository_mirrors, :explicit_refspec, :string, default: ''
  end
end
