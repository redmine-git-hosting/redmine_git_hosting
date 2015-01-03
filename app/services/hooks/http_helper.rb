module Hooks
  module HttpHelper
    unloadable

    private


      def http_post(url, opts = {})
        RedmineGitHosting::HttpUtils.http_post(url, opts)
      end


      def http_get(url, opts = {})
        RedmineGitHosting::HttpUtils.http_get(url, opts)
      end

  end
end
