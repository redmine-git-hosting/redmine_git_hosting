class ExtendChangesetsNotifiedCia < ActiveRecord::Migration
	def self.up
		add_column :changesets, :notified_cia, :integer, :default=>0
	end

	def self.down
		remove_column :changesets, :notified_cia
	end
end
