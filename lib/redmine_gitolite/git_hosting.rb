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


    def self.resync_gitolite(command, object, options = {})
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


    # It calls the block and pass it to stdin pipe.
    # It return the output from stdout.
    # Note that stdout and stderr must be merged by appending '2>&1' in the block command.
    # Raises an exception if the command does not exit with 0.
    #
    # TODO: Use Ruby pipeline? || Enhance pipe_capture below ?
    # http://www.ruby-doc.org/stdlib-2.1.2/libdoc/open3/rdoc/Open3.html#method-c-pipeline_rw
    #
    def self.pipe(command, *params, &block)
      Open3.popen3(command, *params) do |stdin, stdout, stderr, thr|
        begin
          stdin.puts block.call
          stdin.close

          output = stdout.read
          exitcode = thr.value.exitstatus

          if exitcode != 0
            logger.error { output }
            raise GitHostingException.new(command, output)
          end
        ensure
          stdout.close
        end

        return output
      end
    rescue => e
      error_msg = "Exception occured executing `#{command} #{params.join(" ")}` : #{e.message}"
      logger.debug { error_msg }
      raise GitHostingException.new(command, error_msg)
    end


    def self.pipe_capture(*params, stdin)
      command = params.join(' ')
      begin
        stdout, stderr, status = Open3.capture3(command, :stdin_data => stdin, :binmode => true)
      rescue => e
        error_msg = "Exception occured executing `#{command}` : #{e.message}"
        logger.info { error_msg }
        raise GitHostingException.new(command, error_msg)
      end
      return stdout
    end

  end
end
