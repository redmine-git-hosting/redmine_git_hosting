class GitHostingSettingsObserver < ActiveRecord::Observer
	observe :setting

	@@old_valuehash = (Setting.plugin_redmine_git_hosting).clone

	def reload_this_observer
		observed_classes.each do |klass|
			klass.name.constantize.add_observer(self)
		end
	end

        # There is a long-running bug in ActiveRecord::Observer that prevents us from
        # returning from before_save() with false to signal verification failure.
        #
        # Thus, we can only silently refuse to perform bad changes and/or perform
        # slight corrections to badly formatted values.
        def before_save(object)
          	# Only validate settings for our plugin
        	if object.name == "plugin_redmine_git_hosting" 
                	valuehash = object.value
                	if !GitHosting.bin_dir_writeable?
                        	# If bin directory not alterable, don't allow changes to
          			# Git Username, or Gitolite public or private keys
	                	valuehash['gitUser'] = @@old_valuehash['gitUser']
                  		valuehash['gitoliteIdentityFile'] = @@old_valuehash['gitoliteIdentityFile']
                  		valuehash['gitoliteIdentityPublicKeyFile'] = @@old_valuehash['gitoliteIdentityPublicKeyFile']
                	end
                  
                  	# Server should not include any path components
                  	if valuehash['gitServer']
                        	normalizedServer = valuehash['gitServer'].lstrip.rstrip.split('/').first
                        	if (normalizedServer == '')
                                	valuehash['gitServer'] = @@old_valuehash['gitServer']
                                else
                                	valuehash['gitServer'] = normalizedServer
                                end
                        end

                  	# Server should not include any path components
                  	if valuehash['httpServer']
                        	normalizedServer = valuehash['httpServer'].lstrip.rstrip.split('/').first
                        	if (normalizedServer == '')
                                	valuehash['httpServer'] = @@old_valuehash['httpServer']
                                else
                                	valuehash['httpServer'] = normalizedServer
                                end
                        end

                  	# Normalize http repository subdirectory path, should be either empty or relative and end in '/'
                  	if valuehash['httpServerSubdir']
                        	normalizedFile  = File.expand_path(valuehash['httpServerSubdir'].lstrip.rstrip,"/")
                        	if (normalizedFile != "/")
                        		valuehash['httpServerSubdir'] = normalizedFile[1..-1] + "/"  # Clobber leading '/' add trailing '/'
                        	else
                        		valuehash['httpServerSubdir'] = ''
                        	end
                        end
                	
                  	# Normalize Repository path, should be relative and end in '/'
                  	if valuehash['gitRepositoryBasePath']
                        	normalizedFile  = File.expand_path(valuehash['gitRepositoryBasePath'].lstrip.rstrip,"/")
                        	if (normalizedFile != "/")
                        		valuehash['gitRepositoryBasePath'] = normalizedFile[1..-1] + "/"  # Clobber leading '/' add trailing '/'
                        	else
                        		valuehash['gitRepositoryBasePath'] = @@old_valuehash['gitRepositoryBasePath']
                                end
                        end

                  	# Normalize Redmine Subdirectory path, should be either empty or relative and end in '/'
                  	if valuehash['gitRedmineSubdir']
                        	normalizedFile  = File.expand_path(valuehash['gitRedmineSubdir'].lstrip.rstrip,"/")
                        	if (normalizedFile != "/")
                        		valuehash['gitRedmineSubdir'] = normalizedFile[1..-1] + "/"  # Clobber leading '/' add trailing '/'
                        	else
                        		valuehash['gitRedmineSubdir'] = ''
                                end
                        end

                  	# Normalize Recycle bin path, should be relative and end in '/'
                  	if valuehash['gitRecycleBasePath']
                        	normalizedFile  = File.expand_path(valuehash['gitRecycleBasePath'].lstrip.rstrip,"/")
                        	if (normalizedFile != "/")
                        		valuehash['gitRecycleBasePath'] = normalizedFile[1..-1] + "/"  # Clobber leading '/' add trailing '/'
                        	else
                        		valuehash['gitRecycleBasePath'] = @@old_valuehash['gitRecycleBasePath']
                        	end
                        end
                  
                  	# Exclude bad expire times (and exclude non-numbers)
			if valuehash['gitRecycleExpireTime']
                        	if valuehash['gitRecycleExpireTime'].to_f > 0
                                	valuehash['gitRecycleExpireTime'] = "#{(valuehash['gitRecycleExpireTime'].to_f * 10).to_i / 10.0}"
	                        else
                                	valuehash['gitRecycleExpireTime'] = @@old_valuehash['gitRecycleExpireTime']
                                end
                        end

                  	# Validate wait time > 0 (and exclude non-numbers)
                        if valuehash['gitLockWaitTime']
                        	if valuehash['gitLockWaitTime'].to_i > 0
                                	valuehash['gitLockWaitTime'] = "#{valuehash['gitLockWaitTime'].to_i}"
                        	else
                        		valuehash['gitLockWaitTime'] = @@old_valuehash['gitLockWaitTime']
                                end
                        end
                	# Save back results
                	object.value = valuehash
                end
        end
                	
	def after_save(object)
        	# Only perform after-actions on settings for our plugin
		if object.name == "plugin_redmine_git_hosting"
                	valuehash = object.value
                	
			# Settings cache doesn't seem to invalidate symbolic versions of Settings immediately,
                  	# so, any use of Setting.plugin_redmine_git_hosting[] by things called during this
                  	# callback will be outdated.... True for at least some versions of redmine plugin...
                  	#
                  	# John Kubiatowicz 12/21/2011
			if Setting.respond_to?(:check_cache)
                        	# Clear out all cached settings.
                        	Setting.check_cache
                        end

                	if GitHosting.bin_dir_writeable?
				%x[ rm -rf '#{ GitHosting.get_tmp_dir }' ]
				%x[ rm -rf '#{ GitHosting.get_bin_dir }' ] 
                        end

			if @@old_valuehash['gitRepositoryBasePath'] != valuehash['gitRepositoryBasePath'] ||
                           @@old_valuehash['gitRedmineSubdir'] != valuehash['gitRedmineSubdir'] ||
                           @@old_valuehash['gitRepositoryHierarchy'] != valuehash['gitRepositoryHierarchy'] ||
                           @@old_valuehash['gitUser'] != valuehash['gitUser']
                        	# Need to update everyone!
				GitHostingObserver.bracketed_update_repositories(:resync_all)
			end

			if @@old_valuehash['gitUser'] != valuehash['gitUser']

				GitHosting.setup_hooks

			elsif @@old_valuehash['httpServer'] !=  valuehash['httpServer'] || 
                              @@old_valuehash['gitHooksDebug'] != valuehash['gitHooksDebug'] || 
                              @@old_valuehash['gitRedmineSubdir'] != valuehash['gitRedmineSubdir'] ||
                              @@old_valuehash['gitRepositoryHierarchy'] != valuehash['gitRepositoryHierarchy'] ||
                              @@old_valuehash['gitHooksAreAsynchronous'] != valuehash['gitHooksAreAsynchronous']

				GitHosting.update_global_hook_params
			end
                  	@@old_valuehash = valuehash.clone
		end
	end
end
