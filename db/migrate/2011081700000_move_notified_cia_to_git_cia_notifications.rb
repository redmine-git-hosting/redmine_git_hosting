class MoveNotifiedCiaToGitCiaNotifications < ActiveRecord::Migration
	def self.up

		drop_table :git_cia_notifications if self.table_exists?("git_cia_notifications")

		create_table :git_cia_notifications do |t|
			t.column :repository_id, :integer
			t.column :scmid, :string
		end


		# Speed up searches
		add_index(:git_cia_notifications, :scmid)
		# Make sure uniqueness of the two columns, :scmid, :repository_id
		add_index(:git_cia_notifications, [:scmid, :repository_id], :unique => true)

		Project.find(:all).each {|project|
			if project.repository.is_a?(Repository::Git)
				project.repository.changesets.each { |changeset|
					if not changeset.notified_cia.nil? and changeset.notified_cia == 1
						#project.repository.set_notified(changeset)
						project.repository.cia_notifications.push GitCiaNotification.new(:scmid => changeset.scmid)
						#cia_notification = GitCiaNotification.new
						#cia_notification.scmid = changeset.scmid
						#cia_notification.repository = project.repository
						#cia_notification.save
					end
				}
			end
		}
		remove_column :changesets, :notified_cia if self.column_exists?(:changesets, :notified_cia)
	end

	def self.down
		drop_table :git_cia_notifications
	end

	def self.table_exists?(name)
		ActiveRecord::Base.connection.tables.include?(name)
	end

	def self.column_exists?(table_name, column_name)
		columns(table_name).any?{ |c| c.name == column_name.to_s }
	end
end
