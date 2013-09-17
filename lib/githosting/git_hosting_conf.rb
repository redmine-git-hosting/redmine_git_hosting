module GitHostingConf

  ###############################
  ##                           ##
  ##       GITOLITE SSH        ##
  ##                           ##
  ###############################

  GITOLITE_USER                 = 'git'
  GITOLITE_SERVER_PORT          = '22'
  GITOLITE_SSH_PRIVATE_KEY      = File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa').to_s
  GITOLITE_SSH_PUBLIC_KEY       = File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa.pub').to_s
  GITOLITE_ADMIN_REPO           = 'gitolite-admin.git'


  def self.gitolite_user
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_user].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_user]
    else
      GITOLITE_USER
    end
  end


  def self.gitolite_server_port
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_server_port].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_server_port]
    else
      GITOLITE_SERVER_PORT
    end
  end


  def self.gitolite_ssh_private_key
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_ssh_private_key].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_ssh_private_key]
    else
      GITOLITE_SSH_PRIVATE_KEY
    end
  end


  def self.gitolite_ssh_public_key
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_ssh_public_key].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_ssh_public_key]
    else
      GITOLITE_SSH_PUBLIC_KEY
    end
  end


  # Full Gitolite URL
  def self.gitolite_admin_url
    return "#{gitolite_user}@localhost/#{GITOLITE_ADMIN_REPO}"
  end


  ###############################
  ##                           ##
  ##       GITOLITE DIR        ##
  ##                           ##
  ###############################

  GITOLITE_TEMP_DIR             = File.join(ENV['HOME'], 'tmp', 'redmine_git_hosting').to_s
  GITOLITE_SCRIPTS_DIR          = ''
  GITOLITE_SCRIPTS_PARENT_DIR   = 'bin'

  GITOLITE_GLOBAL_STORAGE_DIR   = 'repositories/'
  GITOLITE_REDMINE_STORAGE_DIR  = ''
  GITOLITE_RECYCLE_BIN_DIR      = 'recycle_bin/'


  def self.gitolite_temp_dir
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_temp_dir].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_temp_dir]
    else
      GITOLITE_TEMP_DIR
    end
  end


  def self.gitolite_scripts_dir
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_scripts_dir].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_scripts_dir]
    else
      GITOLITE_SCRIPTS_DIR
    end
  end


  def self.gitolite_scripts_parent_dir
    GITOLITE_SCRIPTS_PARENT_DIR
  end


  # Repository base path (relative to Gitolite user home directory)
  def self.gitolite_global_storage_dir
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_global_storage_dir].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_global_storage_dir]
    else
      GITOLITE_GLOBAL_STORAGE_DIR
    end
  end


  # Redmine subdirectory path (relative to GITOLITE_GLOBAL_STORAGE_DIR)
  def self.gitolite_redmine_storage_dir
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_redmine_storage_dir].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_redmine_storage_dir]
    else
      GITOLITE_REDMINE_STORAGE_DIR
    end
  end


  def self.gitolite_recycle_bin_dir
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_recycle_bin_dir].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_recycle_bin_dir]
    else
      GITOLITE_RECYCLE_BIN_DIR
    end
  end


  ###############################
  ##                           ##
  ##      GITOLITE CONFIG      ##
  ##                           ##
  ###############################

  GITOLITE_CONFIG_FILE                 = 'gitolite.conf'
  GITOLITE_CONFIG_HAS_ADMIN_KEY        = true
  GITOLITE_RECYCLE_BIN_EXPIRATION_TIME = 1440
  GITOLITE_LOCK_WAIT_TIME              = 10
  GITOLITE_HOOKS_ARE_ASYNCHRONOUS      = true
  GITOLITE_FORCE_HOOK_UPDATE           = true
  GITOLITE_HOOKS_DEBUG                 = true
  GITOLITE_LOG_LEVEL                   = 'info'
  GITOLITE_LOG_SPLIT                   = false


  def self.gitolite_config_file
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_config_file].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_config_file]
    else
      GITOLITE_CONFIG_FILE
    end
  end


  def self.gitolite_config_has_admin_key?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_config_has_admin_key].nil?
      if Setting.plugin_redmine_git_hosting[:gitolite_config_has_admin_key] == 'true'
        return true
      else
        return false
      end
    else
      GITOLITE_CONFIG_HAS_ADMIN_KEY
    end
  end


  def self.gitolite_recycle_bin_expiration_time
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_recycle_bin_expiration_time].nil?
      (Setting.plugin_redmine_git_hosting[:gitolite_recycle_bin_expiration_time].to_f * 60).to_i
    else
      GITOLITE_RECYCLE_BIN_EXPIRATION_TIME
    end
  end


  def self.gitolite_lock_wait_time
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_lock_wait_time].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_lock_wait_time].to_i
    else
      GITOLITE_LOCK_WAIT_TIME
    end
  end


  def self.gitolite_hooks_are_asynchronous?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_hooks_are_asynchronous].nil?
      if Setting.plugin_redmine_git_hosting[:gitolite_hooks_are_asynchronous] == 'true'
        return true
      else
        return false
      end
    else
      GITOLITE_HOOKS_ARE_ASYNCHRONOUS
    end
  end


  def self.gitolite_force_hooks_update?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_force_hooks_update].nil?
      if Setting.plugin_redmine_git_hosting[:gitolite_force_hooks_update] == 'true'
        return true
      else
        return false
      end
    else
      GITOLITE_FORCE_HOOK_UPDATE
    end
  end


  def self.gitolite_hooks_debug?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_hooks_debug].nil?
      if Setting.plugin_redmine_git_hosting[:gitolite_hooks_debug] == 'true'
        return true
      else
        return false
      end
    else
      GITOLITE_HOOKS_DEBUG
    end
  end


  def self.gitolite_log_level
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_log_level].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_log_level]
    else
      GITOLITE_LOG_LEVEL
    end
  end


  def self.gitolite_log_split?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_log_split].nil?
      if Setting.plugin_redmine_git_hosting[:gitolite_log_split] == 'true'
        return true
      else
        return false
      end
    else
      GITOLITE_LOG_SPLIT
    end
  end


  ###############################
  ##                           ##
  ##      GITOLITE CACHE       ##
  ##                           ##
  ###############################

  GITOLITE_CACHE_MAX_TIME            = '-1'
  GITOLITE_CACHE_MAX_SIZE            = '16'
  GITOLITE_CACHE_MAX_ELEMENTS        = '100'


  def self.gitolite_cache_max_time
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_cache_max_time].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_cache_max_time]
    else
      GITOLITE_CACHE_MAX_TIME
    end
  end


  def self.gitolite_cache_max_size
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_cache_max_size].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_cache_max_size]
    else
      GITOLITE_CACHE_MAX_SIZE
    end
  end


  def self.gitolite_cache_max_elements
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_cache_max_elements].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_cache_max_elements]
    else
      GITOLITE_CACHE_MAX_ELEMENTS
    end
  end


  ###############################
  ##                           ##
  ##     GITOLITE ACCESS       ##
  ##                           ##
  ###############################

  SSH_SERVER_DOMAIN             = 'localhost'
  HTTP_SERVER_DOMAIN            = 'localhost'
  HTTPS_SERVER_DOMAIN           = ''
  HTTP_SERVER_SUBDIR            = ''
  GITOLITE_DAEMON_BY_DEFAULT    = 0
  GITOLITE_HTTP_BY_DEFAULT      = 1
  SHOW_REPOSITORIES_URL         = true


  def self.ssh_server_domain
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:ssh_server_domain].nil?
      Setting.plugin_redmine_git_hosting[:ssh_server_domain]
    else
      SSH_SERVER_DOMAIN
    end
  end


  def self.http_server_domain
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:http_server_domain].nil?
      Setting.plugin_redmine_git_hosting[:http_server_domain]
    else
      HTTP_SERVER_DOMAIN
    end
  end


  def self.https_server_domain
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:https_server_domain].nil?
      Setting.plugin_redmine_git_hosting[:https_server_domain]
    else
      HTTPS_SERVER_DOMAIN
    end
  end


  def self.http_server_subdir
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:http_server_subdir].nil?
      Setting.plugin_redmine_git_hosting[:http_server_subdir]
    else
      HTTP_SERVER_SUBDIR
    end
  end


  def self.gitolite_daemon_by_default
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_daemon_by_default].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_daemon_by_default]
    else
      GITOLITE_DAEMON_BY_DEFAULT
    end
  end


  def self.gitolite_http_by_default
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_http_by_default].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_http_by_default]
    else
      GITOLITE_HTTP_BY_DEFAULT
    end
  end


  def self.show_repositories_url?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:show_repositories_url].nil?
      if Setting.plugin_redmine_git_hosting[:show_repositories_url] == 'true'
        return true
      else
        return false
      end
    else
      SHOW_REPOSITORIES_URL
    end
  end


  # Server path (minus protocol)
  def self.my_root_url
    # Remove any path from httpServer in case they are leftover from previous installations.
    # No trailing /.
    my_root_path = Redmine::Utils::relative_url_root
    File.join(http_server_domain[/^[^\/]*/], my_root_path, "/")[0..-2]
  end


  ###############################
  ##                           ##
  ##     GIT NOTIFICATIONS     ##
  ##                           ##
  ###############################


  GITOLITE_NOTIFY_CIA_BY_DEFAULT         = 0
  GITOLITE_NOTIFY_BY_DEFAULT             = 1
  GITOLITE_NOTIFY_GLOBAL_PREFIX          = '[REDMINE]'
  GITOLITE_NOTIFY_GLOBAL_SENDER_ADDRESS  = Setting.mail_from.to_s.strip.downcase
  GITOLITE_NOTIFY_GLOBAL_INCLUDE         = []
  GITOLITE_NOTIFY_GLOBAL_EXCLUDE         = []


  def self.gitolite_notify_cia_by_default
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_notify_cia_by_default].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_notify_cia_by_default]
    else
      GITOLITE_NOTIFY_CIA_BY_DEFAULT
    end
  end


  def self.gitolite_notify_by_default
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_notify_by_default].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_notify_by_default]
    else
      GITOLITE_NOTIFY_BY_DEFAULT
    end
  end


  def self.gitolite_notify_global_prefix
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_notify_global_prefix].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_notify_global_prefix]
    else
      GITOLITE_NOTIFY_GLOBAL_PREFIX
    end
  end


  def self.gitolite_notify_global_sender_address
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_notify_global_sender_address].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_notify_global_sender_address]
    else
      GITOLITE_NOTIFY_GLOBAL_SENDER_ADDRESS
    end
  end


  def self.gitolite_notify_global_include
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_notify_global_include].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_notify_global_include]
    else
      GITOLITE_NOTIFY_GLOBAL_INCLUDE
    end
  end


  def self.gitolite_notify_global_exclude
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:gitolite_notify_global_exclude].nil?
      Setting.plugin_redmine_git_hosting[:gitolite_notify_global_exclude]
    else
      GITOLITE_NOTIFY_GLOBAL_EXCLUDE
    end
  end


  ###############################
  ##                           ##
  ##         REDMINE           ##
  ##                           ##
  ###############################

  ALL_PROJECTS_USE_GIT          = false
  DELETE_GIT_REPOSITORIES       = true
  HIERARCHICAL_ORGANISATION     = true
  UNIQUE_REPO_IDENTIFIER        = false


  def self.all_projects_use_git?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:all_projects_use_git].nil?
      if Setting.plugin_redmine_git_hosting[:all_projects_use_git] == 'true'
        return true
      else
        return false
      end
    else
      ALL_PROJECTS_USE_GIT
    end
  end


  def self.delete_git_repositories?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:delete_git_repositories].nil?
      if Setting.plugin_redmine_git_hosting[:delete_git_repositories] == 'true'
        return true
      else
        return false
      end
    else
      DELETE_GIT_REPOSITORIES
    end
  end


  def self.hierarchical_organisation?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:hierarchical_organisation].nil?
      if Setting.plugin_redmine_git_hosting[:hierarchical_organisation] == 'true'
        return true
      else
        return false
      end
    else
      HIERARCHICAL_ORGANISATION
    end
  end


  def self.unique_repo_identifier?
    if !Setting.plugin_redmine_git_hosting.nil? and !Setting.plugin_redmine_git_hosting[:unique_repo_identifier].nil?
      if Setting.plugin_redmine_git_hosting[:unique_repo_identifier] == 'true'
        return true
      else
        return false
      end
    else
      UNIQUE_REPO_IDENTIFIER
    end
  end

end
