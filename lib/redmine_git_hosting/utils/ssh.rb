module RedmineGitHosting::Utils
  module Ssh

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def ssh_fingerprint(key)
        file = Tempfile.new('keytest')
        file.write(key)
        file.close

        begin
          output = capture('ssh-keygen', ['-l', '-f', file.path])
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          raise RedmineGitHosting::Error::InvalidSshKey
        else
          output.split[1]
        ensure
          file.unlink
        end
      end

    end

  end
end
