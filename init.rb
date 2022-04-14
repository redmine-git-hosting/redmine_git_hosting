# frozen_string_literal: true

require 'redmine'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require 'redmine_git_hosting'

Redmine::Plugin.register :redmine_git_hosting do
  name        'Redmine Git Hosting Plugin'
  author      'A lot of people! A big thank to them for their contribution!'
  description 'Enables Redmine to control hosting of Git repositories through Gitolite'
  version     RedmineGitHosting::VERSION
  url         'http://redmine-git-hosting.io/'
  author_url  'settings/plugin/redmine_git_hosting/authors'

  settings partial: 'settings/redmine_git_hosting', default: RedmineGitHosting.settings
  requires_redmine version_or_higher: '4.1.0'

  permission :create_gitolite_ssh_key, gitolite_public_keys: %i[index create destroy], require: :loggedin

  project_module :repository do
    permission :create_repository_mirrors, repository_mirrors: %i[new create]
    permission :view_repository_mirrors,   repository_mirrors: %i[indexshow]
    permission :edit_repository_mirrors,   repository_mirrors: %i[edit update destroy]
    permission :push_repository_mirrors,   repository_mirrors: [:push]

    permission :create_repository_post_receive_urls, repository_post_receive_urls: %i[new create]
    permission :view_repository_post_receive_urls,   repository_post_receive_urls: %i[index show]
    permission :edit_repository_post_receive_urls,   repository_post_receive_urls: %i[edit update destroy]

    permission :create_repository_deployment_credentials, repository_deployment_credentials: %i[new create]
    permission :view_repository_deployment_credentials,   repository_deployment_credentials: %i[index show]
    permission :edit_repository_deployment_credentials,   repository_deployment_credentials: %i[edit update destroy]

    permission :create_repository_git_config_keys, repository_git_config_keys: %i[new create]
    permission :view_repository_git_config_keys,   repository_git_config_keys: %i[index show]
    permission :edit_repository_git_config_keys,   repository_git_config_keys: %i[edit update destroy]

    permission :create_repository_protected_branches, repository_protected_branches: %i[new create]
    permission :view_repository_protected_branches,   repository_protected_branches: %i[index show]
    permission :edit_repository_protected_branches,   repository_protected_branches: %i[edit update destroy]

    permission :view_repository_xitolite_watchers,   repositories: :show
    permission :add_repository_xitolite_watchers,    watchers: :create
    permission :delete_repository_xitolite_watchers, watchers: :destroy

    permission :download_git_revision, download_git_revision: :index
  end

  menu :admin_menu,
       :redmine_git_hosting,
       { controller: 'settings', action: 'plugin', id: 'redmine_git_hosting' },
       caption: :redmine_git_hosting

  menu :project_menu,
       :new_repository,
       { controller: 'repositories', action: 'new' },
       param: :project_id,
       caption: :label_repository_new,
       parent: :new_object

  begin
    requires_redmine_plugin :additionals, version_or_higher: '3.0.3'
  rescue Redmine::PluginNotFound
    raise 'Please install additionals plugin (https://github.com/alphanodes/additionals)'
  end
end

# This *must stay after* Redmine::Plugin.register statement
# because it needs to access to plugin settings...
# so we need the plugin to be fully registered...
Rails.configuration.to_prepare do
  require_dependency 'load_gitolite_hooks'
end
