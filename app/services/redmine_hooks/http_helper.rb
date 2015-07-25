module RedmineHooks
  module HttpHelper
    unloadable

    private


      def http_post(url, opts = {})
        RedmineGitHosting::Utils.http_post(url, opts)
      end


      def http_get(url, opts = {})
        RedmineGitHosting::Utils.http_get(url, opts)
      end

  end
end
