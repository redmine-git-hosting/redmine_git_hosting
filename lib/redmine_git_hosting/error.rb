module RedmineGitHosting
  module Error

    # Used to register errors when pulling and pushing the conf file
    class GitoliteException        < StandardError; end
    class GitoliteWrapperException < GitoliteException; end

    # Used to register errors when pulling and pushing the conf file
    class GitoliteCommandException < GitoliteException
      attr_reader :command
      attr_reader :output

      def initialize(command, output)
        @command = command
        @output  = output
      end
    end

  end
end
