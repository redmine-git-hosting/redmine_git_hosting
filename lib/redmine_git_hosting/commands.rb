module RedmineGitHosting
  module Commands

    include Commands::Git
    include Commands::Sudo
    include Commands::Ssh

    class << self

      def logger
        RedmineGitHosting.logger
      end

    end

  end
end
