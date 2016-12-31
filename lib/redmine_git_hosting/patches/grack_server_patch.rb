require 'grack/server'

module RedmineGitHosting
  module Patches
    module GrackServerPatch

      # Override original *get_git* method to set the right path for the repository.
      # Also pass the *@env['REMOTE_USER']* variable to the Git constructor so we
      # can pass it to Gitolite hooks later.
      def get_git(path)
        path = gitolite_path(path)
        Grack::Git.new(@config[:git_path], path, @env['REMOTE_USER'])
      end

      private

        def gitolite_path(path)
          File.join(RedmineGitHosting::Config.gitolite_home_dir, RedmineGitHosting::Config.gitolite_global_storage_dir, RedmineGitHosting::Config.gitolite_redmine_storage_dir, path)
        end

    end
  end
end

unless Grack::Server.included_modules.include?(RedmineGitHosting::Patches::GrackServerPatch)
  Grack::Server.send(:prepend, RedmineGitHosting::Patches::GrackServerPatch)
end
