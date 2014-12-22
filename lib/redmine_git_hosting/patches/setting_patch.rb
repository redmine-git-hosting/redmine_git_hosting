require_dependency 'setting'

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
        @@resync_projects = false
        @@resync_ssh_keys = false
        @@flush_cache     = false
        @@delete_trash_repo = []

        def save_git_hosting_values
          # Only validate settings for our plugin
          if self.name == 'plugin_redmine_git_hosting'
            valuehash = self.value

            # Temp directory must be absolute and not-empty
            if valuehash[:gitolite_temp_dir] && (valuehash[:gitolite_temp_dir] != @@old_valuehash[:gitolite_temp_dir])

              # Remove old tmp directory, since about to change
              FileUtils.rm_rf(RedmineGitolite::GitoliteWrapper.gitolite_admin_dir)

              stripped = valuehash[:gitolite_temp_dir].lstrip.rstrip

              # Get rid of extra path components
              normalizedFile = File.expand_path(stripped, "/")

              if (normalizedFile == "/" || stripped[0,1] != "/")
                # Don't allow either root-level (absolute) or relative
                valuehash[:gitolite_temp_dir] = RedmineGitolite::GitoliteWrapper.gitolite_admin_dir
              else
                # Add trailing '/'
                valuehash[:gitolite_temp_dir] = normalizedFile + "/"
              end

            end


            # Server domain should not include any path components. Also, ports should be numeric.
            [ :ssh_server_domain, :http_server_domain ].each do |setting|
              if valuehash[setting]
                if valuehash[setting] != ''
                  normalizedServer = valuehash[setting].lstrip.rstrip.split('/').first
                  if (!normalizedServer.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/))
                    valuehash[setting] = @@old_valuehash[setting]
                  else
                    valuehash[setting] = normalizedServer
                  end
                else
                  valuehash[setting] = @@old_valuehash[setting]
                end
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
                valuehash[:gitolite_config_file] = RedmineGitolite::Config::GITOLITE_DEFAULT_CONFIG_FILE
              end

              # Repair key must be true if default path
              if valuehash[:gitolite_config_file] == RedmineGitolite::Config::GITOLITE_DEFAULT_CONFIG_FILE
                valuehash[:gitolite_config_has_admin_key] = 'true'
                valuehash[:gitolite_identifier_prefix] = RedmineGitolite::Config::GITOLITE_IDENTIFIER_DEFAULT_PREFIX
              end
            end


            # Normalize paths, should be relative and end in '/'
            [ :gitolite_global_storage_dir, :gitolite_recycle_bin_dir, :gitolite_local_code_dir ].each do |setting|
              if valuehash[setting]
                normalizedFile  = File.expand_path(valuehash[setting].lstrip.rstrip, "/")
                if (normalizedFile != "/")
                  # Clobber leading '/' add trailing '/'
                  valuehash[setting] = normalizedFile[1..-1] + "/"
                else
                  valuehash[setting] = @@old_valuehash[setting]
                end
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


            # hierarchical_organisation and unique_repo_identifier are now combined
            if valuehash[:hierarchical_organisation] == 'true'
              valuehash[:unique_repo_identifier] = 'false'
            else
              valuehash[:unique_repo_identifier] = 'true'
            end


            # Check duplication if we are switching from a mode to another
            if @@old_valuehash[:hierarchical_organisation] == true && valuehash[:hierarchical_organisation] == 'false'
              if Repository::Gitolite.have_duplicated_identifier?
                # Oops -- have duplication.  Force to true.
                RedmineGitolite::GitHosting.logger.error { "Detected non-unique repository identifiers. Cannot switch to flat mode, setting hierarchical_organisation => 'true'" }
                valuehash[:hierarchical_organisation] = 'true'
                valuehash[:unique_repo_identifier] = 'false'
              else
                valuehash[:hierarchical_organisation] = 'false'
                valuehash[:unique_repo_identifier] = 'true'
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


            # Validate ssh port > 0 and < 65537 (and exclude non-numbers)
            if valuehash[:gitolite_server_port]
              if valuehash[:gitolite_server_port].to_i > 0 and valuehash[:gitolite_server_port].to_i < 65537
                valuehash[:gitolite_server_port] = "#{valuehash[:gitolite_server_port].to_i}"
              else
                valuehash[:gitolite_server_port] = @@old_valuehash[:gitolite_server_port]
              end
            end


            # Validate gitolite_notify mail list
            [ :gitolite_notify_global_include, :gitolite_notify_global_exclude ].each do |setting|
              if !valuehash[setting].empty?
                valuehash[setting] = valuehash[setting].select{|mail| !mail.blank?}
                has_error = 0

                valuehash[setting].each do |item|
                  has_error += 1 unless item =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
                end unless valuehash[setting].empty?

                if has_error > 0
                  valuehash[setting] = @@old_valuehash[setting]
                end
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


            # Validate git author address
            if valuehash[:git_config_email].blank?
              valuehash[:git_config_email] = Setting.mail_from.to_s.strip.downcase
            else
              if !/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.match(valuehash[:git_config_email])
                valuehash[:git_config_email] = @@old_valuehash[:git_config_email]
              end
            end


            ## This a force update
            if valuehash[:gitolite_resync_all_projects] == 'true'
              @@resync_projects = true
              valuehash[:gitolite_resync_all_projects] = 'false'
            end


            ## This a force update
            if valuehash[:gitolite_resync_all_ssh_keys] == 'true'
              @@resync_ssh_keys = true
              valuehash[:gitolite_resync_all_ssh_keys] = 'false'
            end


            ## Flush Gitolite Cache
            if valuehash[:gitolite_flush_cache] == 'true'
              @@flush_cache = true
              valuehash[:gitolite_flush_cache] = 'false'
            end


            ## Empty Recycle Bin
            if valuehash.has_key?(:gitolite_purge_repos) && !valuehash[:gitolite_purge_repos].empty?
              @@delete_trash_repo = valuehash[:gitolite_purge_repos]
              valuehash[:gitolite_purge_repos] = []
            end


            ## If we don't auto-create repository, we cannot create README file
            if valuehash[:all_projects_use_git] == 'false'
              valuehash[:init_repositories_on_create] = 'false'
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
            # Clear out all cached settings.
            Setting.check_cache if Setting.respond_to?(:check_cache)
            RedmineGitolite::GitHosting.resync_gitolite(:flush_settings_cache, 'flush!', {:flush_cache => true})

            # Build options to pass to RestoreSettings object
            opts = {
              resync_projects:   @@resync_projects,
              resync_ssh_keys:   @@resync_ssh_keys,
              delete_trash_repo: @@delete_trash_repo,
              flush_cache:       @@flush_cache
            }

            # Call RestoreSettings
            RestoreSettings.new(@@old_valuehash, valuehash, opts).call

            # Restore default class settings
            @@resync_projects   = false
            @@resync_ssh_keys   = false
            @@flush_cache       = false
            @@delete_trash_repo = []

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
