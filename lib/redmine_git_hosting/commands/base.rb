module RedmineGitHosting
  module Commands
    module Base
      extend self

      # Wrapper to Open3.capture.
      #
      def capture(args = [], opts = {})
        cmd = args.shift
        RedmineGitHosting::Utils::Exec.capture(cmd, args, opts)
      end


      # Wrapper to Open3.capture.
      #
      def execute(args = [], opts = {})
        cmd = args.shift
        RedmineGitHosting::Utils::Exec.execute(cmd, args, opts)
      end


      private


        def logger
          RedmineGitHosting.logger
        end

    end
  end
end
