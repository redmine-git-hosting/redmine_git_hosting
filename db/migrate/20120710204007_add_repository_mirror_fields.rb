class AddRepositoryMirrorFields < ActiveRecord::Migration
  def self.up
    add_column :repository_mirrors, :push_mode, :integer, :default => 0
    add_column :repository_mirrors, :include_all_branches, :boolean, :default => false
    add_column :repository_mirrors, :include_all_tags, :boolean, :default => false
    add_column :repository_mirrors, :explicit_refspec, :string, :default => ""
  end

  def self.down
    remove_column :repository_mirrors, :push_mode
    remove_column :repository_mirrors, :include_all_branches
    remove_column :repository_mirrors, :include_all_tags
    remove_column :repository_mirrors, :explicit_refspec
  end
end
