module Gitolitable
  module Features
    extend ActiveSupport::Concern

    # Always true to force repository fetch_changesets.
    def report_last_commit
      true
    end


    # Always true to force repository fetch_changesets.
    def extra_report_last_commit
      true
    end


    def git_default_branch
      extra[:default_branch]
    end


    def gitolite_hook_key
      extra[:key]
    end


    def git_daemon_enabled?
      extra[:git_daemon]
    end


    def git_annex_enabled?
      extra[:git_annex]
    end


    def git_notification_enabled?
      extra[:git_notify]
    end


    def smart_http_enabled?
      extra[:git_http] != 0
    end


    def https_access_enabled?
      extra[:git_http] == 1 || extra[:git_http] == 2
    end


    def http_access_enabled?
      extra[:git_http] == 3 || extra[:git_http] == 2
    end


    def only_https_access_enabled?
      extra[:git_http] == 1
    end


    def only_http_access_enabled?
      extra[:git_http] == 3
    end


    def protected_branches_enabled?
      extra[:protected_branch]
    end


    def public_project?
      project.is_public?
    end


    def public_repo?
      extra[:public_repo]
    end


    def urls_order
      extra[:urls_order]
    end

  end
end
