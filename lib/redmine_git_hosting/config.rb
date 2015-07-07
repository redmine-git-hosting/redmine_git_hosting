module RedmineGitHosting
  module Config
    GITHUB_ISSUE = 'https://github.com/jbox-web/redmine_git_hosting/issues'
    GITHUB_WIKI  = 'http://redmine-git-hosting.io/configuration/variables/'

    GITOLITE_DEFAULT_CONFIG_FILE       = 'gitolite.conf'
    GITOLITE_IDENTIFIER_DEFAULT_PREFIX = 'redmine_'

    extend Config::Base
    extend Config::GitoliteAccess
    extend Config::GitoliteBase
    extend Config::GitoliteCache
    extend Config::GitoliteConfigTests
    extend Config::GitoliteHooks
    extend Config::GitoliteInfos
    extend Config::GitoliteNotifications
    extend Config::GitoliteStorage
    extend Config::Mirroring
    extend Config::RedmineConfig
  end
end
