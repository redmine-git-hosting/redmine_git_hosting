class AddPostReceiveUrlModes < ActiveRecord::Migration[4.2]
  def change
    add_column :repository_post_receive_urls, :mode, :string, default: 'github'
  end
end
