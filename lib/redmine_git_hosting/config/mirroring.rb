module RedmineGitHosting
  module Config
    module Mirroring
      extend self

      def mirroring_public_key
        @mirroring_public_key ||= MirrorKeysInstaller.mirroring_public_key(gitolite_ssh_public_key)
      end


      def mirroring_keys_installed?
        @mirroring_keys_installed ||= MirrorKeysInstaller.new(gitolite_home_dir, gitolite_ssh_public_key, gitolite_ssh_private_key).installed?
      end


      def gitolite_mirroring_script
        File.join(gitolite_home_dir, '.ssh', 'run_gitolite_admin_ssh')
      end

    end
  end
end
