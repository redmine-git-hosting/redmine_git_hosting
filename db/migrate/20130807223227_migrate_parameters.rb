class MigrateParameters < ActiveRecord::Migration[4.2]
  def up
    ## Prepare default values in case we install Redmine from scratch
    new_setting = {
      # Legacy settings
      gitolite_user: 'git',
      gitolite_server_port: '22',
      gitolite_ssh_private_key: Rails.root.join('plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa').to_s,
      gitolite_ssh_public_key: Rails.root.join('plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa.pub').to_s,

      gitolite_global_storage_dir: 'repositories/',
      gitolite_redmine_storage_dir: '',
      gitolite_recycle_bin_dir: 'recycle_bin/',

      gitolite_temp_dir: Rails.root.join('tmp/redmine_git_hosting').to_s,
      gitolite_scripts_dir: './',
      gitolite_timeout: '10',
      gitolite_config_file: 'gitolite.conf',
      gitolite_recycle_bin_expiration_time: '24.0',

      gitolite_overwrite_existing_hooks: 'true',
      gitolite_hooks_are_asynchronous: 'false',
      gitolite_hooks_debug: 'false',

      gitolite_cache_max_time: '86400',
      gitolite_cache_max_size: '16',
      gitolite_cache_max_elements: '2000',

      ssh_server_domain: 'localhost',
      http_server_domain: 'localhost',
      https_server_domain: '',
      http_server_subdir: '',
      show_repositories_url: 'true',

      gitolite_daemon_by_default: 'false',
      gitolite_http_by_default: '1',

      all_projects_use_git: 'false',
      delete_git_repositories: 'true',
      hierarchical_organisation: 'true',
      unique_repo_identifier: 'false',

      # New features settings
      gitolite_log_level: 'info',

      gitolite_server_host: '127.0.0.1',

      git_config_username: 'Redmine Git Hosting',
      git_config_email: 'redmine@example.net',

      gitolite_use_sidekiq: 'false',
      init_repositories_on_create: 'false',
      download_revision_enabled: 'true',
      gitolite_identifier_prefix: 'redmine_',
      gitolite_identifier_strip_user_id: 'false',

      gitolite_resync_all: 'false',

      gitolite_notify_by_default: 'false',
      gitolite_notify_global_prefix: '[REDMINE]',
      gitolite_notify_global_sender_address: 'redmine@example.net',
      gitolite_notify_global_include: [],
      gitolite_notify_global_exclude: []
    }

    ## Grab current values and update existing settings
    Setting.plugin_redmine_git_hosting&.each do |key, value|
      case key
      # Gitolite SSH Config
      when 'gitUser'
        new_setting[:gitolite_user] = value
      when 'sshServerLocalPort'
        new_setting[:gitolite_server_port] = value
      when 'gitoliteIdentityFile'
        new_setting[:gitolite_ssh_private_key] = value
      when 'gitoliteIdentityPublicKeyFile'
        new_setting[:gitolite_ssh_public_key] = value
      # Gitolite Storage Config
      when 'gitRepositoryBasePath'
        new_setting[:gitolite_global_storage_dir] = value
      when 'gitRedmineSubdir'
        new_setting[:gitolite_redmine_storage_dir] = value
      when 'gitRecycleBasePath'
        new_setting[:gitolite_recycle_bin_dir] = value
      # Gitolite Global Config
      when 'gitTempDataDir'
        new_setting[:gitolite_temp_dir] = value
      when 'gitScriptDir'
        new_setting[:gitolite_scripts_dir] = value
      when 'gitConfigFile'
        new_setting[:gitolite_config_file] = value
      when 'gitRecycleExpireTime'
        new_setting[:gitolite_recycle_bin_expiration_time] = value
      when 'gitLockWaitTime'
        new_setting[:gitolite_timeout] = value

      # Gitolite Hooks Config
      when 'gitHooksAreAsynchronous'
        new_setting[:gitolite_hooks_are_asynchronous] = value
      when 'gitForceHooksUpdate'
        new_setting[:gitolite_overwrite_existing_hooks] = value
      when 'gitHooksDebug'
        new_setting[:gitolite_hooks_debug] = value

      # Gitolite Cache Config
      when 'gitCacheMaxTime'
        new_setting[:gitolite_cache_max_time] = value
      when 'gitCacheMaxSize'
        new_setting[:gitolite_cache_max_size] = value
      when 'gitCacheMaxElements'
        new_setting[:gitolite_cache_max_elements] = value

      # Gitolite Access Config
      when 'gitServer'
        new_setting[:ssh_server_domain] = value
      when 'httpServer'
        new_setting[:http_server_domain] = value
        new_setting[:https_server_domain] = value
      when 'httpServerSubdir'
        new_setting[:http_server_subdir] = value
      when 'gitRepositoriesShowUrl'
        new_setting[:show_repositories_url] = value
      when 'gitDaemonDefault'
        new_setting[:gitolite_daemon_by_default] = if value == 1
                                                     'true'
                                                   else
                                                     'false'
                                                   end
      when 'gitHttpDefault'
        new_setting[:gitolite_http_by_default] = value

      # Redmine Config
      when 'allProjectsUseGit'
        new_setting[:all_projects_use_git] = value
      when 'deleteGitRepositories'
        new_setting[:delete_git_repositories] = value
      when 'gitRepositoryHierarchy'
        if Additionals.true? value
          new_setting[:hierarchical_organisation] = 'true'
          new_setting[:unique_repo_identifier] = 'false'
        else
          new_setting[:hierarchical_organisation] = 'false'
          new_setting[:unique_repo_identifier] = 'true'
        end
      end
    end

    say 'Applying configuration update ...'
    say YAML.dump(new_setting)

    begin
      Setting.plugin_redmine_git_hosting = new_setting
    rescue StandardError => e
      say "Error : #{e.message}"
    else
      say 'Done!'
    end
  end
end
