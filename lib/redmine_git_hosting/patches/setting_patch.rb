module RedmineGitHosting
  module Patches
    module SettingPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          before_save  :save_git_hosting_values
          after_commit :restore_git_hosting_values
        end
      end

      module InstanceMethods

        private

        @@old_valuehash = ((Setting.plugin_redmine_git_hosting).clone rescue {})
        @@resync = false

        def save_git_hosting_values
          # Only validate settings for our plugin
          if self.name == 'plugin_redmine_git_hosting'
            valuehash = self.value

            if !GitHosting.scripts_dir_writeable?
              # If bin directory not alterable, don't allow changes to
              # Script directory, Git Username, or Gitolite public or private keys
              valuehash[:gitolite_script_dir] = @@old_valuehash[:gitolite_script_dir]
              valuehash[:gitolite_user] = @@old_valuehash[:gitolite_user]
              valuehash[:gitolite_ssh_private_key] = @@old_valuehash[:gitolite_ssh_private_key]
              valuehash[:gitolite_ssh_public_key] = @@old_valuehash[:gitolite_ssh_public_key]
              valuehash[:gitolite_server_port] = @@old_valuehash[:gitolite_server_port]

            elsif valuehash[:gitolite_script_dir] && (valuehash[:gitolite_script_dir] != @@old_valuehash[:gitolite_script_dir])

              # Remove old bin directory and scripts, since about to change directory
              %x[ rm -rf '#{ GitHosting.scripts_dir_path }' ]

              # Script directory either absolute or relative to redmine root
              stripped = valuehash[:gitolite_script_dir].lstrip.rstrip

              # Get rid of extra path components
              normalizedFile = File.expand_path(stripped, "/")

              if (normalizedFile == "/")
                # Assume that we are relative bin directory ("/" and "" => "")
                valuehash[:gitolite_script_dir] = "./"
              elsif (stripped[0,1] != "/")
                # Clobber leading '/' add trailing '/'
                valuehash[:gitolite_script_dir] = normalizedFile[1..-1] + "/"
              else
                # Add trailing '/'
                valuehash[:gitolite_script_dir] = normalizedFile + "/"
              end

            elsif valuehash[:gitolite_user] != @@old_valuehash[:gitolite_user] ||
              valuehash[:gitolite_ssh_private_key] != @@old_valuehash[:gitolite_ssh_private_key] ||
              valuehash[:gitolite_ssh_public_key] != @@old_valuehash[:gitolite_ssh_public_key] ||
              valuehash[:gitolite_server_port] != @@old_valuehash[:gitolite_server_port]

              # Remove old scripts, since about to change content (leave directory alone)
              %x[ rm -f '#{ GitHosting.scripts_dir_path }'* ]
            end

            # Temp directory must be absolute and not-empty
            if valuehash[:gitolite_temp_dir] && (valuehash[:gitolite_temp_dir] != @@old_valuehash[:gitolite_temp_dir])
              # Remove old tmp directory, since about to change
              %x[ rm -rf '#{ GitHosting.temp_dir_path }' ]

              stripped = valuehash[:gitolite_temp_dir].lstrip.rstrip

              # Get rid of extra path components
              normalizedFile = File.expand_path(stripped, "/")

              if (normalizedFile == "/" || stripped[0,1] != "/")
                # Don't allow either root-level (absolute) or relative
                valuehash[:gitolite_temp_dir] = GitHosting.temp_dir_path
              else
                # Add trailing '/'
                valuehash[:gitolite_temp_dir] = normalizedFile + "/"
              end

            end

            # SSH server should not include any path components. Also, ports should be numeric.
            if valuehash[:ssh_server_domain]
              normalizedServer = valuehash[:ssh_server_domain].lstrip.rstrip.split('/').first
              if (!normalizedServer.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/))
                valuehash[:ssh_server_domain] = @@old_valuehash[:ssh_server_domain]
              else
                valuehash[:ssh_server_domain] = normalizedServer
              end
            end

            # HTTP server should not include any path components. Also, ports should be numeric.
            if valuehash[:http_server_domain]
              normalizedServer = valuehash[:http_server_domain].lstrip.rstrip.split('/').first
              if (!normalizedServer.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/))
                valuehash[:http_server_domain] = @@old_valuehash[:http_server_domain]
              else
                valuehash[:http_server_domain] = normalizedServer
              end
            end

            # HTTPS server should not include any path components. Also, ports should be numeric.
            if valuehash[:https_server_domain]
              if valuehash[:https_server_domain] != ''
                normalizedServer = valuehash[:https_server_domain].lstrip.rstrip.split('/').first
                if (!normalizedServer.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/))
                  valuehash[:https_server_domain] = @@old_valuehash[:https_server_domain]
                else
                  valuehash[:https_server_domain] = normalizedServer
                end
              end
            end

            # Normalize http repository subdirectory path, should be either empty or relative and end in '/'
            if valuehash[:http_server_subdir]
              normalizedFile  = File.expand_path(valuehash[:http_server_subdir].lstrip.rstrip, "/")
              if (normalizedFile != "/")
                # Clobber leading '/' add trailing '/'
                valuehash[:http_server_subdir] = normalizedFile[1..-1] + "/"
              else
                valuehash[:http_server_subdir] = ''
              end
            end

            # Normalize Config File
            if valuehash[:gitolite_config_file]
              # Must be relative!
              normalizedFile  = File.expand_path(valuehash[:gitolite_config_file].lstrip.rstrip, "/")
              if (normalizedFile != "/")
                # Clobber leading '/'
                valuehash[:gitolite_config_file] = normalizedFile[1..-1]
              else
                valuehash[:gitolite_config_file] = GitHostingConf::GITOLITE_CONFIG_FILE
              end

              # Repair key must be true if default path
              if valuehash[:gitolite_config_file] == GitHostingConf::GITOLITE_CONFIG_FILE
                valuehash[:gitolite_config_has_admin_key] = 'true'
              end
            end

            # Normalize Repository path, should be relative and end in '/'
            if valuehash[:gitolite_global_storage_dir]
              normalizedFile  = File.expand_path(valuehash[:gitolite_global_storage_dir].lstrip.rstrip, "/")
              if (normalizedFile != "/")
                # Clobber leading '/' add trailing '/'
                valuehash[:gitolite_global_storage_dir] = normalizedFile[1..-1] + "/"
              else
                valuehash[:gitolite_global_storage_dir] = @@old_valuehash[:gitolite_global_storage_dir]
              end
            end

            # Normalize Redmine Subdirectory path, should be either empty or relative and end in '/'
            if valuehash[:gitolite_redmine_storage_dir]
              normalizedFile  = File.expand_path(valuehash[:gitolite_redmine_storage_dir].lstrip.rstrip, "/")
              if (normalizedFile != "/")
                # Clobber leading '/' add trailing '/'
                valuehash[:gitolite_redmine_storage_dir] = normalizedFile[1..-1] + "/"
              else
                valuehash[:gitolite_redmine_storage_dir] = ''
              end
            end

            # Normalize Recycle bin path, should be relative and end in '/'
            if valuehash[:gitolite_recycle_bin_dir]
              normalizedFile  = File.expand_path(valuehash[:gitolite_recycle_bin_dir].lstrip.rstrip, "/")
              if (normalizedFile != "/")
                # Clobber leading '/' add trailing '/'
                valuehash[:gitolite_recycle_bin_dir] = normalizedFile[1..-1] + "/"
              else
                valuehash[:gitolite_recycle_bin_dir] = @@old_valuehash[:gitolite_recycle_bin_dir]
              end
            end

            # Check to see if we are trying to claim all repository identifiers are unique
            if valuehash[:unique_repo_identifier] == 'true'
              if ((Repository.all.map(&:identifier).inject(Hash.new(0)) do |h,x|
                  h[x]+=1 unless x.blank?
                  h
                end.values.max) || 0) > 1
                # Oops -- have duplication.  Force to false.
                GitHosting.logger.error "Detected non-unique repository identifiers. Setting unique_repo_identifier => 'false'"
                valuehash[:unique_repo_identifier] = 'false'
              end
            end

            # Exclude bad expire times (and exclude non-numbers)
            if valuehash[:gitolite_recycle_bin_expiration_time]
              if valuehash[:gitolite_recycle_bin_expiration_time].to_f > 0
                valuehash[:gitolite_recycle_bin_expiration_time] = "#{(valuehash[:gitolite_recycle_bin_expiration_time].to_f * 10).to_i / 10.0}"
              else
                valuehash[:gitolite_recycle_bin_expiration_time] = @@old_valuehash[:gitolite_recycle_bin_expiration_time]
              end
            end

            # Validate wait time > 0 (and exclude non-numbers)
            if valuehash[:gitolite_lock_wait_time]
              if valuehash[:gitolite_lock_wait_time].to_i > 0
                valuehash[:gitolite_lock_wait_time] = "#{valuehash[:gitolite_lock_wait_time].to_i}"
              else
                valuehash[:gitolite_lock_wait_time] = @@old_valuehash[:gitolite_lock_wait_time]
              end
            end

            # Validate ssh port > 0 and < 65537 (and exclude non-numbers)
            if valuehash[:gitolite_server_port]
              if valuehash[:gitolite_server_port].to_i > 0 and valuehash[:gitolite_server_port].to_i < 65537
                valuehash[:gitolite_server_port] = "#{valuehash[:gitolite_server_port].to_i}"
              else
                valuehash[:gitolite_server_port] = @@old_valuehash[:gitolite_server_port]
              end
            end

            # Validate gitolite_notify_global_include list of mails
            if !valuehash[:gitolite_notify_global_include].empty?
              valuehash[:gitolite_notify_global_include] = valuehash[:gitolite_notify_global_include].select{|mail| !mail.blank?}
              has_error = 0

              valuehash[:gitolite_notify_global_include].each do |item|
                has_error += 1 unless item =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
              end unless valuehash[:gitolite_notify_global_include].empty?

              if has_error > 0
                valuehash[:gitolite_notify_global_include] = @@old_valuehash[:gitolite_notify_global_include]
              end
            end

            # Validate gitolite_notify_global_exclude list of mails
            if !valuehash[:gitolite_notify_global_exclude].empty?
              valuehash[:gitolite_notify_global_exclude] = valuehash[:gitolite_notify_global_exclude].select{|mail| !mail.blank?}
              has_error = 0

              valuehash[:gitolite_notify_global_exclude].each do |item|
                has_error += 1 unless item =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
              end unless valuehash[:gitolite_notify_global_exclude].empty?

              if has_error > 0
                valuehash[:gitolite_notify_global_exclude] = @@old_valuehash[:gitolite_notify_global_exclude]
              end
            end

            # Validate intersection of global_include/global_exclude
            intersection = valuehash[:gitolite_notify_global_include] & valuehash[:gitolite_notify_global_exclude]
            if intersection.length.to_i > 0
              valuehash[:gitolite_notify_global_include] = @@old_valuehash[:gitolite_notify_global_include]
              valuehash[:gitolite_notify_global_exclude] = @@old_valuehash[:gitolite_notify_global_exclude]
            end

            # Validate global sender address
            if valuehash[:gitolite_notify_global_sender_address].blank?
              valuehash[:gitolite_notify_global_sender_address] = Setting.mail_from.to_s.strip.downcase
            else
              if !/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.match(valuehash[:gitolite_notify_global_sender_address])
                valuehash[:gitolite_notify_global_sender_address] = @@old_valuehash[:gitolite_notify_global_sender_address]
              end
            end

            ## This a force update
            if valuehash[:gitolite_resync_all] == 'true'
              @@resync = true
              valuehash[:gitolite_resync_all] = false
            end

            # Save back results
            self.value = valuehash
          end
        end

        def restore_git_hosting_values
          # Only perform after-actions on settings for our plugin
          if self.name == 'plugin_redmine_git_hosting'
            valuehash = self.value

            # Settings cache doesn't seem to invalidate symbolic versions of Settings immediately,
            # so, any use of Setting.plugin_redmine_git_hosting[] by things called during this
            # callback will be outdated.... True for at least some versions of redmine plugin...
            #
            # John Kubiatowicz 12/21/2011
            if Setting.respond_to?(:check_cache)
              # Clear out all cached settings.
              Setting.check_cache
            end

            ## SSH infos has changed, update scripts!
            if @@old_valuehash[:gitolite_script_dir] != valuehash[:gitolite_script_dir] ||
               @@old_valuehash[:gitolite_user] != valuehash[:gitolite_user] ||
               @@old_valuehash[:gitolite_ssh_private_key] != valuehash[:gitolite_ssh_private_key] ||
               @@old_valuehash[:gitolite_ssh_public_key] != valuehash[:gitolite_ssh_public_key] ||
               @@old_valuehash[:gitolite_server_port] != valuehash[:gitolite_server_port]
                # Need to update scripts
                GitHosting.update_gitolite_scripts
            end

            ## Storage infos has changed, move repositories!
            if @@old_valuehash[:gitolite_global_storage_dir] != valuehash[:gitolite_global_storage_dir] ||
               @@old_valuehash[:gitolite_redmine_storage_dir] != valuehash[:gitolite_redmine_storage_dir] ||
               @@old_valuehash[:hierarchical_organisation] != valuehash[:hierarchical_organisation]
                # Need to update everyone!
                projects = Project.active_or_archived.find(:all, :include => :repositories).select { |x| x if x.parent_id.nil? }
                if projects.length > 0
                  GitHosting.logger.info "Gitolite configuration has been modified : repositories hierarchy"
                  GitHosting.logger.info "Resync all projects (root projects : '#{projects.length}')..."
                  #~ GithostingShellWorker.perform_async({ :command => :move_repositories_tree, :object => projects.length, :option => :flush_cache })
                end
            end

            ## Gitolite config file has changed, create a new one!
            if @@old_valuehash[:gitolite_config_file] != valuehash[:gitolite_config_file] ||
               @@old_valuehash[:gitolite_config_has_admin_key] != valuehash[:gitolite_config_has_admin_key] ||
               @@old_valuehash[:unique_repo_identifier] != valuehash[:unique_repo_identifier] ||
               @@old_valuehash[:gitolite_notify_global_prefix] != valuehash[:gitolite_notify_global_prefix] ||
               @@old_valuehash[:gitolite_notify_global_sender_address] != valuehash[:gitolite_notify_global_sender_address] ||
               @@old_valuehash[:gitolite_notify_global_include] != valuehash[:gitolite_notify_global_include] ||
               @@old_valuehash[:gitolite_notify_global_exclude] != valuehash[:gitolite_notify_global_exclude]
                # Need to update everyone!
                projects = Project.active_or_archived.find(:all, :include => :repositories)
                if projects.length > 0
                  GitHosting.logger.info "Gitolite configuration has been modified, resync all projects..."
                  #~ GithostingShellWorker.perform_async({ :command => :update_all_projects, :object => projects.length })
                end
            end

            ## Gitolite user has changed, check if this new one has our hooks!
            if @@old_valuehash[:gitolite_user] != valuehash[:gitolite_user]
              GitHosting.check_hooks_installed
            end

            ## A resync has been asked within the interface, update all projects in force mode
            if @@resync == true
              # Need to update everyone!
              projects = Project.active_or_archived.find(:all, :include => :repositories)
              if projects.length > 0
                GitHosting.logger.info "Forced resync of all projects..."
                #~ GithostingShellWorker.perform_async({ :command => :update_all_projects_forced, :object => projects.length })
              end

              @@resync = false
            end

            ## Gitolite hooks config has changed, update our .gitconfig!
            if @@old_valuehash[:http_server_domain] !=  valuehash[:http_server_domain] ||
               @@old_valuehash[:https_server_domain] !=  valuehash[:https_server_domain] ||
               @@old_valuehash[:gitolite_hooks_debug] != valuehash[:gitolite_hooks_debug] ||
               @@old_valuehash[:gitolite_force_hooks_update] != valuehash[:gitolite_force_hooks_update] ||
               @@old_valuehash[:gitolite_hooks_are_asynchronous] != valuehash[:gitolite_hooks_are_asynchronous]
                # Need to update our .gitconfig
                GitHosting.update_global_hook_params
            end

            ## Gitolite cache has changed, clear cache entries!
            if @@old_valuehash[:gitolite_cache_max_time] != valuehash[:gitolite_cache_max_time]
              GitHostingCache.clear_obsolete_cache_entries
            end

            @@old_valuehash = valuehash.clone
          end
        end

      end

    end
  end
end

unless Setting.included_modules.include?(RedmineGitHosting::Patches::SettingPatch)
  Setting.send(:include, RedmineGitHosting::Patches::SettingPatch)
end
