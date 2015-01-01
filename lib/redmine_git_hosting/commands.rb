module RedmineGitHosting
  module Commands

    include Commands::Git
    include Commands::Gitolite
    include Commands::Sudo
    include Commands::Ssh

    class << self

      private


        def gitolite_home_dir
          RedmineGitHosting::Config.gitolite_home_dir
        end


        def gitolite_command
          RedmineGitHosting::Config.gitolite_command
        end


        def logger
          RedmineGitHosting.logger
        end

    end

  end
end
