require 'digest/sha1'

class GitRepositoryExtra < ActiveRecord::Base

	belongs_to :repository, :class_name => 'Repository', :foreign_key => 'repository_id'
	validates_associated :repository
	attr_accessible :id, :repository_id, :key, :git_http, :git_daemon, :notify_cia

	def after_initialize
		if self.repository.nil?
			generate
			setup_defaults        	
                end
	end

	def validate_encoded_time(clear_time, encoded_time)
		valid = false
		begin
			cur_time_seconds = Time.new.utc.to_i
			test_time_seconds = clear_time.to_i
			if cur_time_seconds - test_time_seconds < 5*60
				key = read_attribute(:key)
				test_encoded = Digest::SHA1.hexdigest(clear_time.to_s + key.to_s)
				if test_encoded.to_s == encoded_time.to_s
					valid = true
				end
			end
		rescue Exception=>e
		end
		valid
	end

	def generate
		if self.key.nil?
			write_attribute(:key, (0...64+rand(64) ).map{65.+(rand(25)).chr}.join )
			self.save
		end
	end

	def setup_defaults
        	write_attribute(:git_http,Setting.plugin_redmine_git_hosting['gitHttpDefault']) if Setting.plugin_redmine_git_hosting['gitHttpDefault']
        	write_attribute(:git_daemon,Setting.plugin_redmine_git_hosting['gitDaemonDefault']) if Setting.plugin_redmine_git_hosting['gitDaemonDefault']
        	write_attribute(:notify_cia,Setting.plugin_redmine_git_hosting['gitNotifyCIADefault']) if Setting.plugin_redmine_git_hosting['gitNotifyCIADefault']
        	self.save
        end
                                        
end
