module RedmineGitHosting::Config
  module Mirroring

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def mirroring_public_key
        RedmineGitHosting::MirrorKeysInstaller.mirroring_public_key(gitolite_ssh_public_key)
      end


      def mirroring_keys_installed?
        @mirroring_keys_installed ||= RedmineGitHosting::MirrorKeysInstaller.new(gitolite_home_dir, gitolite_ssh_public_key, gitolite_ssh_private_key).installed?
      end


      def gitolite_mirroring_script
        File.join(gitolite_home_dir, '.ssh', 'run_gitolite_admin_ssh')
      end

    end

  end
end
