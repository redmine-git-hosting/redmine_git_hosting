module RedmineGitHosting
  module Utils
    module Ssh
      extend self

      def ssh_fingerprint(key)
        file = Tempfile.new('keytest')
        file.write(key)
        file.close

        begin
          output = Utils::Exec.capture('ssh-keygen', ['-l', '-f', file.path])
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          raise RedmineGitHosting::Error::InvalidSshKey.new("Invalid Ssh Key : #{key}")
        else
          output.split[1]
        ensure
          file.unlink
        end
      end


      def sanitize_ssh_key(key)
        # First -- let the first control char or space stand (to divide key type from key)
        # Really, this is catching a special case in which there is a \n between type and key.
        # Most common case turns first space back into space....
        key = key.sub(/[ \r\n\t]/, ' ')

        # Next, if comment divided from key by control char, let that one stand as well
        # We can only tell this if there is an "=" in the key. So, won't help 1/3 times.
        key = key.sub(/=[ \r\n\t]/, '= ')

        # Delete any remaining control characters....
        key = key.gsub(/[\a\r\n\t]/, '').strip

        # Return the sanitized key
        key
      end

    end
  end
end
