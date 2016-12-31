# coding: utf-8

require 'redmine'

require 'redmine_git_hosting'

Redmine::Plugin.register :redmine_git_hosting do
  name        'Redmine Git Hosting Plugin'
  author      'A lot of people! A big thank to them for their contribution!'
  description 'Enables Redmine to control hosting of Git repositories through Gitolite'
  version     '1.2.2'
  url         'http://redmine-git-hosting.io/'
  author_url  '/settings/plugin/redmine_git_hosting/authors'

  settings({ partial: 'settings/redmine_git_hosting', default: RedmineGitHosting.settings })
end

# This *must stay after* Redmine::Plugin.register statement
# because it needs to access to plugin settings...
# so we need the plugin to be fully registered...
Rails.configuration.to_prepare do
  require_dependency 'load_gitolite_hooks'
end
