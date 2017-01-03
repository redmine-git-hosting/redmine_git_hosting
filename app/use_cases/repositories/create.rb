module Repositories
  class Create < Base

    def call
      set_repository_extra
      create_repository
    end


    private


      def set_repository_extra
        extra = repository.build_extra(default_extra_options)
        extra.save!
      end


      def default_extra_options
        enable_git_annex? ? git_annex_repository_options : standard_repository_options
      end


      def enable_git_annex?
        options[:enable_git_annex]
      end


      def standard_repository_options
        {
          git_daemon:     RedmineGitHosting::Config.gitolite_daemon_by_default?,
          git_notify:     RedmineGitHosting::Config.gitolite_notify_by_default?,
          git_annex:      false,
          default_branch: 'master',
          key:            RedmineGitHosting::Utils::Crypto.generate_secret(64)
        }.merge(smart_http_options)
      end


      def smart_http_options
        case RedmineGitHosting::Config.gitolite_http_by_default?
        when '1' # HTTPS only
          { git_https: true }
        when '2' # HTTPS and HTTP
          { git_http: true, git_https: true }
        when '3' # HTTP only
          { git_http: true }
        else
          {}
        end
      end


      def git_annex_repository_options
        {
          git_http:       0,
          git_daemon:     false,
          git_notify:     false,
          git_annex:      true,
          default_branch: 'git-annex',
          key:            RedmineGitHosting::Utils::Crypto.generate_secret(64)
        }
      end


      def create_repository
        gitolite_accessor.create_repository(repository, options)
      end

  end
end
