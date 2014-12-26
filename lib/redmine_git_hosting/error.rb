module RedmineGitHosting
  module Error

    # Used to register errors when pulling and pushing the conf file
    class GitoliteException < StandardError
      attr_reader :command
      attr_reader :output

      def initialize(command, output)
        @command = command
        @output  = output
      end
    end

    # Used to register errors when pulling and pushing the conf file
    class GitoliteCommandException < GitoliteException; end
    class GitoliteWrapperException < GitoliteException; end

  end
end
