# coding: utf-8

require 'redmine'

require 'redmine_git_hosting'

Redmine::Plugin.register :redmine_git_hosting do
  name 'Redmine Git Hosting Plugin'
  author 'Eric Bishop, Pedro Algarvio, Christian Käser, Zsolt Parragi, Yunsang Choi, Joshua Hogendorn, Jan Schulz-Hofen, John Kubiatowicz, Nicolas Rodriguez and others'
  description 'Enables Redmine to control hosting of Git repositories through Gitolite'
  version '1.0.7'
  url 'https://github.com/jbox-web/redmine_git_hosting'
  author_url 'https://github.com/jbox-web'

  settings({
    :partial => 'settings/redmine_git_hosting',
    :default => {
      # Gitolite SSH Config
      :gitolite_user                  => 'git',
      :gitolite_server_port           => '22',
      :gitolite_ssh_private_key       => Rails.root.join('plugins', 'redmine_git_hosting', 'ssh_keys', 'redmine_gitolite_admin_id_rsa').to_s,
      :gitolite_ssh_public_key        => Rails.root.join('plugins', 'redmine_git_hosting', 'ssh_keys', 'redmine_gitolite_admin_id_rsa.pub').to_s,

      # Gitolite Storage Config
      :gitolite_global_storage_dir    => 'repositories/',
      :gitolite_redmine_storage_dir   => '',
      :gitolite_recycle_bin_dir       => 'recycle_bin/',
      :gitolite_local_code_dir        => 'local/',

      # Gitolite Config File
      :gitolite_config_file           => 'gitolite.conf',
      :gitolite_config_has_admin_key  => 'true',
      :gitolite_identifier_prefix     => 'redmine_',

      # Gitolite Global Config
      :gitolite_temp_dir                     => Rails.root.join('tmp', 'redmine_git_hosting').to_s,
      :gitolite_recycle_bin_expiration_time  => '24.0',
      :gitolite_log_level                    => 'info',
      :git_config_username                   => 'Redmine Git Hosting',
      :git_config_email                      => 'redmine@example.net',

      # Gitolite Hooks Config
      :gitolite_overwrite_existing_hooks => 'true',
      :gitolite_hooks_are_asynchronous   => 'false',
      :gitolite_hooks_debug              => 'false',
      :gitolite_hooks_url                => 'http://localhost:3000',

      # Gitolite Cache Config
      :gitolite_cache_max_time          => '86400',
      :gitolite_cache_max_size          => '16',
      :gitolite_cache_max_elements      => '2000',
      :gitolite_cache_adapter           => 'database',

      # Gitolite Access Config
      :ssh_server_domain                => 'localhost',
      :http_server_domain               => 'localhost',
      :https_server_domain              => 'localhost',
      :http_server_subdir               => '',
      :show_repositories_url            => 'true',
      :gitolite_daemon_by_default       => 'false',
      :gitolite_http_by_default         => '1',

      # Redmine Config
      :all_projects_use_git             => 'false',
      :init_repositories_on_create      => 'false',
      :delete_git_repositories          => 'true',

      # This params work together!
      # When hierarchical_organisation = true, unique_repo_identifier MUST be false
      # When hierarchical_organisation = false, unique_repo_identifier MUST be true
      :hierarchical_organisation        => 'true',
      :unique_repo_identifier           => 'false',

      # Download Revision Config
      :download_revision_enabled        => 'true',

      # Git Mailing List Config
      :gitolite_notify_by_default            => 'false',
      :gitolite_notify_global_prefix         => '[REDMINE]',
      :gitolite_notify_global_sender_address => 'redmine@example.net',
      :gitolite_notify_global_include        => [],
      :gitolite_notify_global_exclude        => [],

      # Sidekiq Config
      :gitolite_use_sidekiq                  => 'false',
    }
  })

  Redmine::AccessControl.map do |map|
    map.permission :create_gitolite_ssh_key, gitolite_public_keys: [:index, :create, :destroy], require: :loggedin

    map.project_module :repository do |map|
      map.permission :create_repository_mirrors, repository_mirrors: [:new, :create]
      map.permission :view_repository_mirrors,   repository_mirrors: [:index, :show]
      map.permission :edit_repository_mirrors,   repository_mirrors: [:edit, :update, :destroy]
      map.permission :push_repository_mirrors,   repository_mirrors: [:push]

      map.permission :create_repository_post_receive_urls, repository_post_receive_urls: [:new, :create]
      map.permission :view_repository_post_receive_urls,   repository_post_receive_urls: [:index, :show]
      map.permission :edit_repository_post_receive_urls,   repository_post_receive_urls: [:edit, :update, :destroy]

      map.permission :create_repository_deployment_credentials, repository_deployment_credentials: [:new, :create]
      map.permission :view_repository_deployment_credentials,   repository_deployment_credentials: [:index, :show]
      map.permission :edit_repository_deployment_credentials,   repository_deployment_credentials: [:edit, :update, :destroy]

      map.permission :create_repository_git_config_keys, repository_git_config_keys: [:new, :create]
      map.permission :view_repository_git_config_keys,   repository_git_config_keys: [:index, :show]
      map.permission :edit_repository_git_config_keys,   repository_git_config_keys: [:edit, :update, :destroy]

      map.permission :create_repository_protected_branches, repository_protected_branches: [:new, :create]
      map.permission :view_repository_protected_branches,   repository_protected_branches: [:index, :show]
      map.permission :edit_repository_protected_branches,   repository_protected_branches: [:edit, :update, :destroy]

      map.permission :create_repository_git_notifications, repository_git_notifications: [:new, :create]
      map.permission :view_repository_git_notifications,   repository_git_notifications: [:index, :show]
      map.permission :edit_repository_git_notifications,   repository_git_notifications: [:edit, :update, :destroy]

      map.permission :receive_git_notifications, gitolite_hooks: :post_receive
      map.permission :download_git_revision,     download_git_revision: :index
    end
  end

  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :redmine_git_hosting, { controller: 'settings', action: 'plugin', id: 'redmine_git_hosting' }, caption: :redmine_git_hosting
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :archived_repositories, { controller: '/archived_repositories', action: 'index' }, caption: :label_archived_repositories, after: :administration,
              if: Proc.new { User.current.logged? && User.current.admin? }
  end

  Redmine::Scm::Base.add 'Xitolite'
end

# This *must stay after* Redmine::Plugin.register statement
# because it needs to access to plugin settings...
# so we need the plugin to be fully registered...
Rails.configuration.to_prepare do
  require_dependency 'load_gitolite_hooks'
end
