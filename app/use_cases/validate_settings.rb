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


    def default_mail
      Setting.mail_from.to_s.strip.downcase
    end


    def filter_list(list)
      list.select{ |m| !m.blank? }.select{ |m| valid_email?(m) }
    end


    def convert_time(time)
      (time.to_f * 10).to_i / 10.0
    end


    def valid_server_port?(port)
      port.to_i > 0 && port.to_i < 65537
    end


    def valid_domain_name?(domain)
      domain.match(/^[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*(:\d+)?$/i)
    end


    def valid_email?(email)
      email.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
    end


    def value_has_changed?(params)
      valuehash[params] != old_valuehash[params]
    end


    def strip_value(value)
      value.lstrip.rstrip
    end


    def normalize_path(path)
      File.expand_path(strip_value(path), '/')
    end


    def sanitize_path(path)
      path[1..-1]
    end


    def validate_settings
      cleanup_tmp_dir
      validate_auto_create
      validate_tmp_dir
      validate_mandatory_domain_name
      validate_optional_domain_name
      validate_git_config_file
      validate_mandatory_storage_dir
      validate_optional_subdirs
      validate_storage_strategy
      validate_expiration_time
      validate_git_server_port
      validate_git_notifications_list
      validate_git_notifications_intersection
      validate_emails
      validate_gitolite_hooks_url
    end


    def cleanup_tmp_dir
      if valuehash[:gitolite_temp_dir] && value_has_changed?(:gitolite_temp_dir) ||
         valuehash[:gitolite_server_port] && value_has_changed?(:gitolite_server_port)

        # Remove old tmp directory, since about to change
        FileUtils.rm_rf(RedmineGitHosting::GitoliteWrapper.gitolite_admin_dir)
      end
    end


    def validate_auto_create
      ## If we don't auto-create repository, we cannot create README file
      valuehash[:init_repositories_on_create] = 'false' if valuehash[:all_projects_use_git] == 'false'
    end


    def validate_tmp_dir
      # Temp directory must be absolute and not-empty
      if valuehash[:gitolite_temp_dir] && value_has_changed?(:gitolite_temp_dir)
        # Get rid of extra path components
        stripped = strip_value(valuehash[:gitolite_temp_dir])
        gitolite_temp_dir = normalize_path(valuehash[:gitolite_temp_dir])

        if gitolite_temp_dir == '/' || stripped[0,1] != '/'
          # Don't allow either root-level (absolute) or relative
          valuehash[:gitolite_temp_dir] = RedmineGitHosting::GitoliteWrapper.gitolite_admin_dir
        else
          # Add trailing '/'
          valuehash[:gitolite_temp_dir] = gitolite_temp_dir + '/'
        end
      end
    end


    def validate_mandatory_domain_name
      # Server domain should not include any path components. Also, ports should be numeric.
      [ :ssh_server_domain, :http_server_domain ].each do |setting|
        if valuehash[setting]
          if valuehash[setting] != ''
            normalized_param = strip_value(valuehash[setting])
            if valid_domain_name?(normalized_param)
              valuehash[setting] = old_valuehash[setting]
            else
              valuehash[setting] = normalized_param
            end
          else
            valuehash[setting] = old_valuehash[setting]
          end
        end
      end
    end


    def validate_optional_domain_name
      # HTTPS server should not include any path components. Also, ports should be numeric.
      if valuehash[:https_server_domain]
        if valuehash[:https_server_domain] != ''
          domain_name = strip_value(valuehash[:https_server_domain])
          if valid_domain_name?(domain_name)
            valuehash[:https_server_domain] = old_valuehash[:https_server_domain]
          else
            valuehash[:https_server_domain] = domain_name
          end
        end
      end
    end


    def validate_git_config_file
      # Normalize Config File
      if valuehash[:gitolite_config_file]
        # Must be relative!
        gitolite_config_file = normalize_path(valuehash[:gitolite_config_file])
        if gitolite_config_file != '/'
          # Clobber leading '/'
          valuehash[:gitolite_config_file] = sanitize_path(gitolite_config_file)
        else
          valuehash[:gitolite_config_file] = RedmineGitHosting::Config::GITOLITE_DEFAULT_CONFIG_FILE
        end

        # Repair key must be true if default path
        if valuehash[:gitolite_config_file] == RedmineGitHosting::Config::GITOLITE_DEFAULT_CONFIG_FILE
          valuehash[:gitolite_config_has_admin_key] = 'true'
          valuehash[:gitolite_identifier_prefix] = RedmineGitHosting::Config::GITOLITE_IDENTIFIER_DEFAULT_PREFIX
        end
      end
    end


    def validate_mandatory_storage_dir
      # Normalize paths, should be relative and end in '/'
      [ :gitolite_global_storage_dir, :gitolite_recycle_bin_dir, :gitolite_local_code_dir ].each do |setting|
        if valuehash[setting]
          normalized_param = normalize_path(valuehash[setting])
          if normalized_param != '/'
            # Clobber leading '/' add trailing '/'
            valuehash[setting] = sanitize_path(normalized_param) + '/'
          else
            valuehash[setting] = old_valuehash[setting]
          end
        end
      end
    end


    def validate_optional_subdirs
      # Normalize Redmine Subdirectory path, should be either empty or relative and end in '/'
      [ :gitolite_redmine_storage_dir, :http_server_subdir ].each do |setting|
        if valuehash[setting]
          normalized_param = normalize_path(valuehash[setting])
          if normalized_param != '/'
            # Clobber leading '/' add trailing '/'
            valuehash[setting] = sanitize_path(normalized_param) + '/'
          else
            valuehash[setting] = ''
          end
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
          RedmineGitHosting.logger.error("Detected non-unique repository identifiers. Cannot switch to flat mode, setting hierarchical_organisation => 'true'")
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
          valuehash[:gitolite_recycle_bin_expiration_time] = convert_time(valuehash[:gitolite_recycle_bin_expiration_time])
        else
          valuehash[:gitolite_recycle_bin_expiration_time] = old_valuehash[:gitolite_recycle_bin_expiration_time]
        end
      end
    end


    def validate_git_server_port
      # Validate ssh port > 0 and < 65537 (and exclude non-numbers)
      if valuehash[:gitolite_server_port]
        if !valid_server_port?(valuehash[:gitolite_server_port])
          valuehash[:gitolite_server_port] = old_valuehash[:gitolite_server_port]
        end
      end
    end


    def validate_git_notifications_list
      # Validate gitolite_notify mail list
      [ :gitolite_notify_global_include, :gitolite_notify_global_exclude ].each do |setting|
        if !valuehash[setting].empty?
          valuehash[setting] = filter_list(valuehash[setting])
        end
      end
    end


    def validate_git_notifications_intersection
      # Validate intersection of global_include/global_exclude
      intersection = valuehash[:gitolite_notify_global_include] & valuehash[:gitolite_notify_global_exclude]
      if intersection.length.to_i > 0
        valuehash[:gitolite_notify_global_include] = old_valuehash[:gitolite_notify_global_include]
        valuehash[:gitolite_notify_global_exclude] = old_valuehash[:gitolite_notify_global_exclude]
      end
    end


    def validate_emails
      [ :gitolite_notify_global_sender_address, :git_config_email ].each do |setting|
        if valuehash[setting].blank?
          valuehash[setting] = default_mail
        elsif !valid_email?(valuehash[setting])
          valuehash[setting] = old_valuehash[setting]
        end
      end
    end


    def validate_gitolite_hooks_url
      if valuehash[:gitolite_hooks_url]
        if !RedmineGitHosting::Utils.valid_url?(valuehash[:gitolite_hooks_url])
          valuehash[:gitolite_hooks_url] = old_valuehash[:gitolite_hooks_url]
        end
      end
    end

end
