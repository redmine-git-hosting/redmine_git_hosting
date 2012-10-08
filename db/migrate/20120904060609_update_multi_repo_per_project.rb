class UpdateMultiRepoPerProject < ActiveRecord::Migration
    def self.up
	begin
	    add_column :repository_mirrors, :repository_id, :integer
	    begin
		say "Detaching repository mirrors from projects; attaching them to repositories..."
		RepositoryMirror.all.each do |mirror|
		    mirror.repository_id = Project.find(mirror.project_id).repository.id
		    mirror.save!
		end
		say "Success.  Changed #{RepositoryMirror.all.count} records."
		remove_column :repository_mirrors, :project_id rescue nil
	    rescue => e
		say "Failed to attach repository mirrors to repositories."
		say "Error: #{e.message}"
		remove_column :repository_mirrors, :repository_id rescue nil
	    end
	rescue
	end

	begin
	    add_column :repository_post_receive_urls, :repository_id, :integer
	    begin
		say "Detaching repository post-receive-urls from projects; attaching them to repositories..."
		RepositoryPostReceiveUrl.all.each do |prurl|
		    prurl.repository_id = Project.find(prurl.project_id).repository.id
		    prurl.save!
		end
		say "Success.  Changed #{RepositoryPostReceiveUrl.all.count} records."
		remove_column :repository_post_receive_urls, :project_id rescue nil
	    rescue => e
		say "Failed to attach repositories post-receive-urls to repositories."
		say "Error: #{e.message}"
		remove_column :repository_post_receive_urls, :repository_id rescue nil
	    end
	rescue
	end

	add_index :projects, [:identifier]
	begin
	    add_index :repositories, [:identifier]
	    add_index :repositories, [:identifier, :project_id]
	rescue
	end
	rename_column :git_caches, :proj_identifier, :repo_identifier

	begin
	    # Add some new settings to settings page, if they don't exist
	    valuehash = (Setting.plugin_redmine_git_hosting).clone
	    if ((Repository.all.map(&:identifier).inject(Hash.new(0)) do |h,x|
		    h[x]+=1 unless x.blank?
		    h
		 end.values.max) || 0) > 1
		# Oops -- have duplication.	 Force to false.
		valuehash['gitRepositoryIdentUnique'] = "false"
	    else
		# If no duplication -- set to true only if it doesn't already exist
		valuehash['gitRepositoryIdentUnique'] ||= 'true'
	    end

	    if (Setting.plugin_redmine_git_hosting != valuehash)
		say "Added redmine_git_hosting settings: 'gitRepositoryIdentUnique' => #{valuehash['gitRepositoryIdentUnique']}"
		Setting.plugin_redmine_git_hosting = valuehash
	    end
	rescue => e
	    # ignore problems if plugin settings don't exist yet
	end
    end

    def self.down
	begin
	    add_column :repository_mirrors, :project_id, :integer
	    begin
		say "Detaching repository mirrors from repositories; re-attaching them to projects..."
		RepositoryMirror.all.each do |mirror|
		    mirror.project_id = Repository.find(mirror.repository_id).project.id
		    mirror.save!
		end
		say "Success.  Changed #{RepositoryMirror.all.count} records."
		remove_column :repository_mirrors, :repository_id rescue nil
	  rescue => e
		say "Failed to re-attach repository mirrors to projects."
		say "Error: #{e.message}"
		remove_column :repository_mirrors, :project_id rescue nil
	    end
	rescue
	end

	begin
	    add_column :repository_post_receive_urls, :project_id, :integer
	    begin
		say "Detaching repository post-receive-urls from repositories; re-attaching them to projects..."
		RepositoryPostReceiveUrl.all.each do |prurl|
		    prurl.project_id = Repository.find(prurl.repository_id).project.id
		    prurl.save!
		end
		say "Success.  Changed #{RepositoryPostReceiveUrl.all.count} records."
		remove_column :repository_post_receive_urls, :repository_id rescue nil
	    rescue => e
		say "Failed to re-attach repository post-receive urls to projects."
		say "Error: #{e.message}"
		remove_column :repository_post_receive_urls, :project_id rescue nil
	    end
	rescue
	end

	remove_index :projects, [:identifier]
	begin
	    remove_index :repositories, [:identifier]
	    remove_index :repositories, [:identifier, :project_id]
	rescue
	end
	rename_column :git_caches, :repo_identifier, :proj_identifier

	begin
	    # Remove above settings from plugin page
	    valuehash = (Setting.plugin_redmine_git_hosting).clone
	    valuehash.delete('gitRepositoryIdentUnique')

	    if (Setting.plugin_redmine_git_hosting != valuehash)
		say "Removed redmine_git_hosting settings: 'gitRepositoryIdentUnique'"
		Setting.plugin_redmine_git_hosting = valuehash
	    end
	rescue => e
	    # ignore problems if table doesn't exist yet....
	end
    end
end
