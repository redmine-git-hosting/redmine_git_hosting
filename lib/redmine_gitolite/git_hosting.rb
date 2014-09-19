require 'open3'

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


      # Executes the given command and a list of parameters on the shell
      # and returns the result.
      #
      # If the operation throws an exception or the operation yields a non-zero exit code
      # we rethrow a +GitHostingException+ with a meaningful error message.
      def capture(command, args = [], opts = {})
        output, err, code = execute(command, args, opts)
        if code != 0
          error_msg = "Non-zero exit code #{code} for `#{command} #{args.join(" ")}`"
          logger.debug { error_msg }
          raise GitHostingException.new(command, error_msg)
        end

        output
      end


      # Executes the given command and a list of parameters on the shell
      # and returns stdout, stderr, and the exit code.
      #
      # If the operation throws an exception or the operation we rethrow a
      # +GitHostingException+ with a meaningful error message.
      def execute(command, args = [], opts = {})
        Open3.capture3(command, *args, opts)
      rescue => e
        error_msg = "Exception occured executing `#{command} #{args.join(" ")}` : #{e.message}"
        logger.debug { error_msg }
        raise GitHostingException.new(command, error_msg)
      end

    end

  end
end
