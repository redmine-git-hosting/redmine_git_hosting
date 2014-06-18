require 'open3'

module RedmineGitolite

  module GitHosting


    def self.logger
      RedmineGitolite::Log.get_logger(:global)
    end


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


    def self.resync_gitolite(data_hash)
      if data_hash.has_key?(:options)
        if data_hash[:options].has_key?(:flush_cache) && data_hash[:options][:flush_cache] == true
          logger.info { "Flush Settings Cache !" }
          Setting.check_cache
        end
      else
        data_hash[:options] = {}
      end

      if RedmineGitolite::Config.get_setting(:gitolite_use_sidekiq)
        GithostingShellWorker.perform_async(data_hash)
      else
        # githosting_shell = RedmineGitolite::Shell.new(data_hash[:command], data_hash[:object], data_hash[:options])
        # githosting_shell.handle_command

        RedmineGitolite::GitoliteWrapper.update(data_hash[:command], data_hash[:object], data_hash[:options])
      end
    end


    # Returns a rails cache identifier with the key as its last part
    def self.cache_key(key)
      ['/redmine/plugin/redmine_git_hosting/', key].join
    end


    # Executes the given command and a list of parameters on the shell
    # and returns the result.
    #
    # If the operation throws an exception or the operation yields a non-zero exit code
    # we rethrow a +GitHostingException+ with a meaningful error message.
    def self.capture(command, *params)
      output, err, code = execute(command, *params)
      if code != 0
        error_msg = "Non-zero exit code #{code} for `#{command} #{params.join(" ")}`"
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
    def self.execute(command, *params)
      Open3.capture3(command, *params)
    rescue => e
      error_msg = "Exception occured executing `#{command} #{params.join(" ")}` : #{e.message}"
      logger.debug { error_msg }
      raise GitHostingException.new(command, error_msg)
    end

  end
end
