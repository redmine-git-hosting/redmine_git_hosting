module RedmineGitolite
  module GitHosting

    # Used to register errors when pulling and pushing the conf file
    class GitHostingException < StandardError
      attr_reader :command
      attr_reader :output

      def initialize(command, output)
        @command = command
        @output  = output
      end
    end


    ###############################
    ##                           ##
    ##       SHELL WRAPPERS      ##
    ##                           ##
    ###############################


    class << self

      def logger
        RedmineGitolite::Log.get_logger(:global)
      end


      def resync_gitolite(command, object, options = {})
        if options.has_key?(:bypass_sidekiq) && options[:bypass_sidekiq] == true
          bypass = true
        else
          bypass = false
        end

        if RedmineGitolite::Config.get_setting(:gitolite_use_sidekiq, true) && !bypass
          GithostingShellWorker.perform_async(command, object, options)
        else
          RedmineGitolite::GitoliteWrapper.update(command, object, options)
        end
      end

    end

  end
end
