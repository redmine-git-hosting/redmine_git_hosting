require 'open3'

module RedmineGitolite
  module Utils

    class << self

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
          raise RedmineGitolite::GitHosting::GitHostingException.new(command, error_msg)
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
        raise RedmineGitolite::GitHosting::GitHostingException.new(command, error_msg)
      end

    end

  end
end
