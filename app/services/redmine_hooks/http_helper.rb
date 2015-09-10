module RedmineHooks
  module HttpHelper

    def http_post(url, opts = {})
      RedmineGitHosting::Utils::Http.http_post(url, opts)
    end


    def http_get(url, opts = {})
      RedmineGitHosting::Utils::Http.http_get(url, opts)
    end

  end
end
