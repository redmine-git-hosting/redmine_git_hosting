class ExtendRepositoriesNotifyCia < ActiveRecord::Migration
	def self.up
		add_column :repositories, :notify_cia, :integer, :default=>0
	end

	def self.down
		remove_column :repositories, :notify_cia
	end
end
