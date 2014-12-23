class ValidateSettings
  unloadable

  attr_reader :old_valuehash
  attr_reader :valuehash


  def initialize(old_valuehash, valuehash, opts = {})
    @old_valuehash = old_valuehash
    @valuehash     = valuehash
  end


  def call
    validate_settings
    valuehash.merge(default_settings)
  end


  private


    def default_settings
      {
        gitolite_resync_all_projects: 'false',
        gitolite_resync_all_ssh_keys: 'false',
        gitolite_flush_cache:         'false',
        gitolite_purge_repos:         []
      }
    end


    def validate_settings
      validate_auto_create
      validate_tmp_dir
      validate_domain_name
      validate_http_subdir
      validate_git_config_file
      validate_storage_dir
      validate_storage_strategy
      validate_expiration_time
      validate_git_server_port
      validate_git_notifications
    end


    def validate_auto_create
      ## If we don't auto-create repository, we cannot create README file
      valuehash[:init_repositories_on_create] = 'false' if valuehash[:all_projects_use_git] == 'false'
    end


    def validate_tmp_dir
      # Temp directory must be absolute and not-empty
      if valuehash[:gitolite_temp_dir] && (valuehash[:gitolite_temp_dir] != old_valuehash[:gitolite_temp_dir])
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
    end


    def validate_domain_name
      # Server domain should not include any path components. Also, ports should be numeric.
      [ :ssh_server_domain, :http_server_domain ].each do |setting|
        if valuehash[setting]
          if valuehash[setting] != ''
            normalizedServer = valuehash[setting].lstrip.rstrip.split('/').first
            if (!normalizedServer.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/))
              valuehash[setting] = old_valuehash[setting]
            else
              valuehash[setting] = normalizedServer
            end
          else
            valuehash[setting] = old_valuehash[setting]
          end
        end
      end

      # HTTPS server should not include any path components. Also, ports should be numeric.
      if valuehash[:https_server_domain]
        if valuehash[:https_server_domain] != ''
          normalizedServer = valuehash[:https_server_domain].lstrip.rstrip.split('/').first
          if (!normalizedServer.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/))
            valuehash[:https_server_domain] = old_valuehash[:https_server_domain]
          else
            valuehash[:https_server_domain] = normalizedServer
          end
        end
      end
    end


    def validate_http_subdir
      # Normalize http repository subdirectory path, should be either empty or relative and end in '/'
      if valuehash[:http_server_subdir]
        normalizedFile = File.expand_path(valuehash[:http_server_subdir].lstrip.rstrip, "/")
        if (normalizedFile != "/")
          # Clobber leading '/' add trailing '/'
          valuehash[:http_server_subdir] = normalizedFile[1..-1] + "/"
        else
          valuehash[:http_server_subdir] = ''
        end
      end
    end


    def validate_git_config_file
      # Normalize Config File
      if valuehash[:gitolite_config_file]
        # Must be relative!
        normalizedFile = File.expand_path(valuehash[:gitolite_config_file].lstrip.rstrip, "/")
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
    end


    def validate_storage_dir
      # Normalize paths, should be relative and end in '/'
      [ :gitolite_global_storage_dir, :gitolite_recycle_bin_dir, :gitolite_local_code_dir ].each do |setting|
        if valuehash[setting]
          normalizedFile = File.expand_path(valuehash[setting].lstrip.rstrip, "/")
          if (normalizedFile != "/")
            # Clobber leading '/' add trailing '/'
            valuehash[setting] = normalizedFile[1..-1] + "/"
          else
            valuehash[setting] = old_valuehash[setting]
          end
        end
      end


      # Normalize Redmine Subdirectory path, should be either empty or relative and end in '/'
      if valuehash[:gitolite_redmine_storage_dir]
        normalizedFile = File.expand_path(valuehash[:gitolite_redmine_storage_dir].lstrip.rstrip, "/")
        if (normalizedFile != "/")
          # Clobber leading '/' add trailing '/'
          valuehash[:gitolite_redmine_storage_dir] = normalizedFile[1..-1] + "/"
        else
          valuehash[:gitolite_redmine_storage_dir] = ''
        end
      end
    end


    def validate_storage_strategy
      # hierarchical_organisation and unique_repo_identifier are now combined
      if valuehash[:hierarchical_organisation] == 'true'
        valuehash[:unique_repo_identifier] = 'false'
      else
        valuehash[:unique_repo_identifier] = 'true'
      end


      # Check duplication if we are switching from a mode to another
      if old_valuehash[:hierarchical_organisation] == 'true' && valuehash[:hierarchical_organisation] == 'false'
        if Repository::Xitolite.have_duplicated_identifier?
          # Oops -- have duplication.  Force to true.
          RedmineGitolite::GitHosting.logger.error { "Detected non-unique repository identifiers. Cannot switch to flat mode, setting hierarchical_organisation => 'true'" }
          valuehash[:hierarchical_organisation] = 'true'
          valuehash[:unique_repo_identifier] = 'false'
        else
          valuehash[:hierarchical_organisation] = 'false'
          valuehash[:unique_repo_identifier] = 'true'
        end
      end
    end


    def validate_expiration_time
      # Exclude bad expire times (and exclude non-numbers)
      if valuehash[:gitolite_recycle_bin_expiration_time]
        if valuehash[:gitolite_recycle_bin_expiration_time].to_f > 0
          valuehash[:gitolite_recycle_bin_expiration_time] = "#{(valuehash[:gitolite_recycle_bin_expiration_time].to_f * 10).to_i / 10.0}"
        else
          valuehash[:gitolite_recycle_bin_expiration_time] = old_valuehash[:gitolite_recycle_bin_expiration_time]
        end
      end
    end


    def validate_git_server_port
      # Validate ssh port > 0 and < 65537 (and exclude non-numbers)
      if valuehash[:gitolite_server_port]
        if valuehash[:gitolite_server_port].to_i > 0 and valuehash[:gitolite_server_port].to_i < 65537
          valuehash[:gitolite_server_port] = "#{valuehash[:gitolite_server_port].to_i}"
        else
          valuehash[:gitolite_server_port] = old_valuehash[:gitolite_server_port]
        end
      end
    end


    def validate_git_notifications
      # Validate gitolite_notify mail list
      [ :gitolite_notify_global_include, :gitolite_notify_global_exclude ].each do |setting|
        if !valuehash[setting].empty?
          valuehash[setting] = valuehash[setting].select{|mail| !mail.blank?}
          has_error = 0

          valuehash[setting].each do |item|
            has_error += 1 unless item =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
          end unless valuehash[setting].empty?

          if has_error > 0
            valuehash[setting] = old_valuehash[setting]
          end
        end
      end


      # Validate intersection of global_include/global_exclude
      intersection = valuehash[:gitolite_notify_global_include] & valuehash[:gitolite_notify_global_exclude]
      if intersection.length.to_i > 0
        valuehash[:gitolite_notify_global_include] = old_valuehash[:gitolite_notify_global_include]
        valuehash[:gitolite_notify_global_exclude] = old_valuehash[:gitolite_notify_global_exclude]
      end


      # Validate global sender address
      if valuehash[:gitolite_notify_global_sender_address].blank?
        valuehash[:gitolite_notify_global_sender_address] = Setting.mail_from.to_s.strip.downcase
      else
        if !/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.match(valuehash[:gitolite_notify_global_sender_address])
          valuehash[:gitolite_notify_global_sender_address] = old_valuehash[:gitolite_notify_global_sender_address]
        end
      end


      # Validate git author address
      if valuehash[:git_config_email].blank?
        valuehash[:git_config_email] = Setting.mail_from.to_s.strip.downcase
      else
        if !/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.match(valuehash[:git_config_email])
          valuehash[:git_config_email] = old_valuehash[:git_config_email]
        end
      end
    end

end
