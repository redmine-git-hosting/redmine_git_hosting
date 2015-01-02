module RedmineGitHosting::Config

  module GitoliteAccess

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_http_by_default?
        RedmineGitHosting::Config.get_setting(:gitolite_http_by_default)
      end


      def gitolite_daemon_by_default?
        RedmineGitHosting::Config.get_setting(:gitolite_daemon_by_default, true)
      end


      def gitolite_notify_by_default?
        RedmineGitHosting::Config.get_setting(:gitolite_notify_by_default, true)
      end


      def ssh_server_domain
        RedmineGitHosting::Config.get_setting(:ssh_server_domain)
      end


      def http_server_domain
        RedmineGitHosting::Config.get_setting(:http_server_domain)
      end


      def https_server_domain
        RedmineGitHosting::Config.get_setting(:https_server_domain)
      end


      def http_server_subdir
        RedmineGitHosting::Config.get_setting(:http_server_subdir)
      end


      def http_root_url
        my_root_url(false)
      end


      def https_root_url
        my_root_url(true)
      end


      def my_root_url(ssl = false)
        # Remove any path from httpServer in case they are leftover from previous installations.
        # No trailing /.
        my_root_path = Redmine::Utils::relative_url_root

        if ssl && https_server_domain != ''
          server_domain = https_server_domain
        else
          server_domain = http_server_domain
        end

        my_root_url = File.join(server_domain[/^[^\/]*/], my_root_path, '/')[0..-2]

        return my_root_url
      end

    end

  end
end
