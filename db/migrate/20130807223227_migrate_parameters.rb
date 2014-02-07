class MigrateParameters < ActiveRecord::Migration
  def self.up
    new_setting = {}

    ## Prepare default values in case we install Redmine from scratch
    # Legacy settings
    new_setting[:gitolite_user]                 = 'git'
    new_setting[:gitolite_server_port]          = '22'
    new_setting[:gitolite_ssh_private_key]      = File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa').to_s
    new_setting[:gitolite_ssh_public_key]       = File.join(ENV['HOME'], '.ssh', 'redmine_gitolite_admin_id_rsa.pub').to_s

    new_setting[:gitolite_global_storage_dir]   = 'repositories/'
    new_setting[:gitolite_redmine_storage_dir]  = ''
    new_setting[:gitolite_recycle_bin_dir]      = 'recycle_bin/'

    new_setting[:gitolite_temp_dir]                    = File.join(ENV['HOME'], 'tmp', 'redmine_git_hosting').to_s
    new_setting[:gitolite_script_dir]                  = './'
    new_setting[:gitolite_config_file]                 = 'gitolite.conf'
    new_setting[:gitolite_config_has_admin_key]        = false
    new_setting[:gitolite_recycle_bin_expiration_time] = '24.0'
    new_setting[:gitolite_lock_wait_time]              = '10'

    new_setting[:gitolite_hooks_debug]            = true
    new_setting[:gitolite_force_hooks_update]     = true
    new_setting[:gitolite_hooks_are_asynchronous] = false

    new_setting[:gitolite_cache_max_time] = '900'
    new_setting[:gitolite_cache_max_size] = '16'
    new_setting[:gitolite_cache_max_elements] = '2000'

    new_setting[:ssh_server_domain]     = GitHostingConf.my_root_url
    new_setting[:http_server_domain]    = GitHostingConf.my_root_url
    new_setting[:https_server_domain]   = ''
    new_setting[:http_server_subdir]    = ''
    new_setting[:show_repositories_url] = true

    new_setting[:gitolite_notify_cia_by_default] = '0'
    new_setting[:gitolite_daemon_by_default]     = '0'
    new_setting[:gitolite_http_by_default]       = '1'

    new_setting[:all_projects_use_git]      = false
    new_setting[:delete_git_repositories]   = false
    new_setting[:hierarchical_organisation] = false
    new_setting[:unique_repo_identifier]    = true

    # New features settings
    new_setting[:gitolite_log_level]   = 'info'
    new_setting[:gitolite_log_split]   = false
    new_setting[:gitolite_resync_all]  = false

    new_setting[:gitolite_notify_by_default] = '1'
    new_setting[:gitolite_notify_global_prefix] = '[REDMINE]'
    new_setting[:gitolite_notify_global_sender_address] = Setting.mail_from.to_s.strip.downcase
    new_setting[:gitolite_notify_global_include] = []
    new_setting[:gitolite_notify_global_exclude] = []


    ## Grab current values and update existing settings
    if !Setting[:plugin_redmine_git_hosting].nil?
      Setting[:plugin_redmine_git_hosting].each do |key, value|
        case key

          # Gitolite SSH Config
          when 'gitUser' then
            new_setting[:gitolite_user] = value

          when 'sshServerLocalPort' then
            new_setting[:gitolite_server_port] = value

          when 'gitoliteIdentityFile' then
            new_setting[:gitolite_ssh_private_key] = value

          when 'gitoliteIdentityPublicKeyFile' then
            new_setting[:gitolite_ssh_public_key] = value

          # Gitolite Storage Config
          when 'gitRepositoryBasePath' then
            new_setting[:gitolite_global_storage_dir] = value

          when 'gitRedmineSubdir' then
            new_setting[:gitolite_redmine_storage_dir] = value

          when 'gitRecycleBasePath' then
            new_setting[:gitolite_recycle_bin_dir] = value

          # Gitolite Global Config
          when 'gitTempDataDir' then
            new_setting[:gitolite_temp_dir] = value

          when 'gitScriptDir' then
            new_setting[:gitolite_script_dir] = value

          when 'gitConfigFile' then
            new_setting[:gitolite_config_file] = value

          when 'gitConfigHasAdminKey' then
            new_setting[:gitolite_config_has_admin_key] = value

          when 'gitRecycleExpireTime' then
            new_setting[:gitolite_recycle_bin_expiration_time] = value

          when 'gitLockWaitTime' then
            new_setting[:gitolite_lock_wait_time] = value

          # Gitolite Hooks Config
          when 'gitHooksAreAsynchronous' then
            new_setting[:gitolite_hooks_are_asynchronous] = value

          when 'gitForceHooksUpdate' then
            new_setting[:gitolite_force_hooks_update] = value

          when 'gitHooksDebug' then
            new_setting[:gitolite_hooks_debug] = value

          # Gitolite Cache Config
          when 'gitCacheMaxTime' then
            new_setting[:gitolite_cache_max_time] = value

          when 'gitCacheMaxSize' then
            new_setting[:gitolite_cache_max_size] = value

          when 'gitCacheMaxElements' then
            new_setting[:gitolite_cache_max_elements] = value

          # Gitolite Access Config
          when 'gitServer' then
            new_setting[:ssh_server_domain] = value

          when 'httpServer' then
            new_setting[:http_server_domain] = value
            new_setting[:https_server_domain] = value

          when 'httpServerSubdir' then
            new_setting[:http_server_subdir] = value

          when 'gitRepositoriesShowUrl' then
            new_setting[:show_repositories_url] = value

          when 'gitDaemonDefault' then
            new_setting[:gitolite_daemon_by_default] = value

          when 'gitHttpDefault' then
            new_setting[:gitolite_http_by_default] = value

          when 'gitNotifyCIADefault' then
            new_setting[:gitolite_notify_cia_by_default] = value

          # Redmine Config
          when 'allProjectsUseGit' then
            new_setting[:all_projects_use_git] = value

          when 'deleteGitRepositories' then
            new_setting[:delete_git_repositories] = value

          when 'gitRepositoryHierarchy' then
            new_setting[:hierarchical_organisation] = value

          when 'gitRepositoryIdentUnique' then
            new_setting[:unique_repo_identifier] = value

        end
      end
    end

    puts "Applying configuration update"
    puts YAML::dump(new_setting)

    GitHostingObserver.set_update_active(false)
    Setting[:plugin_redmine_git_hosting] = new_setting
  end

end
