module RedmineGitHosting
  module Config
    module GitoliteAccess
      extend self

      def gitolite_http_by_default?
        get_setting(:gitolite_http_by_default)
      end


      def gitolite_daemon_by_default?
        get_setting(:gitolite_daemon_by_default, true)
      end


      def gitolite_notify_by_default?
        get_setting(:gitolite_notify_by_default, true)
      end


      def ssh_server_domain
        get_setting(:ssh_server_domain)
      end


      def http_server_domain
        get_setting(:http_server_domain)
      end


      def https_server_domain
        get_setting(:https_server_domain)
      end


      def http_server_subdir
        get_setting(:http_server_subdir)
      end


      def http_root_url
        my_root_url(false)
      end


      def https_root_url
        my_root_url(true)
      end


      def redmine_root_url
        Redmine::Utils::relative_url_root
      end


      def my_root_url(ssl = false)
        if ssl && https_server_domain != ''
          server_domain = https_server_domain
        else
          server_domain = http_server_domain
        end

        # Remove any path from httpServer.
        # No trailing /.
        File.join(server_domain[/^[^\/]*/], redmine_root_url, '/')[0..-2]
      end

    end
  end
end
