class ExtendChangesetsNotifiedCia < ActiveRecord::Migration
    def self.up
	add_column :changesets, :notified_cia, :integer, :default=>0
    end

    def self.down
	# Deal with fact that one of next migrations doesn't restore :notified_cia
	remove_column(:changesets, :notified_cia) rescue nil
    end
end
