module GitolitableUrls
  extend ActiveSupport::Concern

  def http_user_login
    User.current.anonymous? ? '' : "#{User.current.login}@"
  end


  def git_access_path
    "#{gitolite_repository_name}.git"
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
    "http://#{http_user_login}#{RedmineGitHosting::Config.http_server_domain}/#{http_access_path}"
  end


  def https_url
    "https://#{http_user_login}#{RedmineGitHosting::Config.https_server_domain}/#{http_access_path}"
  end


  def git_annex_url
    "#{RedmineGitHosting::Config.gitolite_user}@#{RedmineGitHosting::Config.ssh_server_domain}:#{git_access_path}"
  end


  def go_access_url
    case extra[:git_http]
    # 1 : Only https is available, good :)
    # 2 : If both http and https are available, https is prefered
    when 1, 2
      https_url
    # 3 : Only http is available, that's okay for git clone
    when 3
      http_url
    # 0 : None is available, return empty string
    when 0
      ''
    end
  end


  def go_url
    case extra[:git_http]
    # 1 : Only https is available, good :)
    # 2 : If both http and https are available, https is prefered
    when 1, 2
      "#{RedmineGitHosting::Config.https_server_domain}/#{go_access_path}"
    # 3 : Only http is available, that's okay for git clone
    when 3
      "#{RedmineGitHosting::Config.http_server_domain}/#{go_access_path}"
    # 0 : None is available, return empty string
    when 0
      ''
    end
  end


  def ssh_access
    { url: ssh_url, committer: allowed_to_commit? }
  end


  ## Unsecure channels (clear password), commit is disabled
  def http_access
    { url: http_url, committer: 'false' }
  end


  def https_access
    { url: https_url, committer: allowed_to_commit? }
  end


  def git_access
    { url: git_url, committer: 'false' }
  end


  def git_annex_access
    { url: git_annex_url, committer: allowed_to_commit? }
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

end
