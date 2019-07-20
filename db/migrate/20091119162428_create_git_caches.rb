class CreateGitCaches < ActiveRecord::Migration[4.2]
  def change
    create_table :git_caches do |t|
      t.column :command, :text
      t.column :command_output, :binary
      t.column :proj_identifier, :string
      t.timestamps
    end
  end
end
