class GitHookKey < ActiveRecord::Base
	attr_accessible :update_key

	@@the_key = nil
	def self.get
		if @@the_key.nil?
			key_list=GitHookKey.find(:all)
			if key_list.length > 0
				@@the_key = key_list.shift.update_key
			else
				GitHosting.logger.debug "Generating the GitHosting Hooks Key"
				@@the_key = (0...20+rand(20)).map{65.+(rand(25)).chr}.join
				k = GitHookKey.new(:update_key=>@@the_key)
				k.save
			end
		end
		@@the_key
	end

end
