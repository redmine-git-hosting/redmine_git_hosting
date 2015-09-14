module Gitolitable
  module Urls
    extend ActiveSupport::Concern

    def http_user_login
      User.current.anonymous? ? '' : "#{User.current.login}@"
    end


    def git_access_path
      gitolite_repository_name_with_extension
    end


    def http_access_path
      "#{RedmineGitHosting::Config.http_server_subdir}#{redmine_repository_path}.git"
    end


    def go_access_path
      "go/#{redmine_repository_path}"
    end


    def ssh_url
      "ssh://#{RedmineGitHosting::Config.gitolite_user}@#{RedmineGitHosting::Config.ssh_server_domain}/#{git_access_path}"
    end


    def git_url
      "git://#{RedmineGitHosting::Config.ssh_server_domain}/#{git_access_path}"
    end


    def http_url
      "http://#{http_user_login}#{RedmineGitHosting::Config.http_root_url}/#{http_access_path}"
    end


    def https_url
      "https://#{http_user_login}#{RedmineGitHosting::Config.https_root_url}/#{http_access_path}"
    end


    def git_annex_url
      "#{RedmineGitHosting::Config.gitolite_user}@#{RedmineGitHosting::Config.ssh_server_domain}:#{git_access_path}"
    end


    # This is the url used by Go to clone repository
    #
    def go_access_url
      return '' if !smart_http_enabled?
      return https_url if https_access_available?
      return http_url if http_access_available?
    end


    # This is the url to add in Go files
    #
    def go_url
      return '' if !smart_http_enabled?
      return "#{RedmineGitHosting::Config.https_root_url}/#{go_access_path}" if https_access_available?
      return "#{RedmineGitHosting::Config.http_root_url}/#{go_access_path}" if http_access_available?
    end


    def ssh_access
      { url: ssh_url, committer: User.current.allowed_to_commit?(self).to_s }
    end


    ## Unsecure channels (clear password), commit is disabled
    def http_access
      { url: http_url, committer: 'false' }
    end


    def https_access
      { url: https_url, committer: User.current.allowed_to_commit?(self).to_s }
    end


    def git_access
      { url: git_url, committer: 'false' }
    end


    def git_annex_access
      { url: git_annex_url, committer: User.current.allowed_to_commit?(self).to_s }
    end


    def go_access
      { url: go_url, committer: 'false' }
    end


    def available_urls
      hash = {}
      hash[:ssh]       = ssh_access if ssh_access_available?
      hash[:https]     = https_access if https_access_available?
      hash[:http]      = http_access if http_access_available?
      hash[:git]       = git_access if git_access_available?
      hash[:go]        = go_access if go_access_available?
      hash[:git_annex] = git_annex_access if git_annex_access_available?
      hash
    end


    def available_urls_sorted
      return available_urls if urls_order.nil? || urls_order.empty?
      hash = {}
      urls_order.each do |url|
        next if !available_urls[url.to_sym]
        hash[url.to_sym] = available_urls[url.to_sym]
      end
      hash
    end

  end
end
