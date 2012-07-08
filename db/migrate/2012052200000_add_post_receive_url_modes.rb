class AddPostReceiveUrlModes < ActiveRecord::Migration
  def self.up
    add_column :repository_post_receive_urls, :mode, :string, :default => "github"
  end

  def self.down
    remove_column :repository_post_receive_urls, :mode
  end
end