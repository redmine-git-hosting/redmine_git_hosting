module RedmineGitHosting
  class MirrorKeysInstaller

    attr_reader :gitolite_home_dir
    attr_reader :gitolite_ssh_public_key
    attr_reader :gitolite_ssh_private_key

    GITOLITE_MIRRORING_KEYS_NAME = 'redmine_gitolite_admin_id_rsa_mirroring'


    def initialize(gitolite_home_dir, gitolite_ssh_public_key, gitolite_ssh_private_key)
      @gitolite_home_dir        = gitolite_home_dir
      @gitolite_ssh_public_key  = gitolite_ssh_public_key
      @gitolite_ssh_private_key = gitolite_ssh_private_key
    end


    class << self

      def mirroring_public_key(gitolite_ssh_public_key)
        begin
          format_mirror_key(File.read(gitolite_ssh_public_key))
        rescue => e
          RedmineGitHosting.logger.error("Error while loading mirroring public key : #{e.output}")
          nil
        end
      end


      def format_mirror_key(key)
        key = key.chomp.strip
        key.split(/[\t ]+/)[0].to_s + ' ' + key.split(/[\t ]+/)[1].to_s
      end

    end


    def installed?
      installable? && install!
    end


    def installable?
      return false if gitolite_home_dir.nil?
      return false if gitolite_ssh_public_key_content.nil?
      return false if gitolite_ssh_private_key_content.nil?
      return true
    end


    def install!
      logger.info('Installing Redmine Gitolite mirroring SSH keys ...')
      installed = install_public_key && install_private_key && install_mirroring_script
      logger.info('Done!')
      installed
    end


    def install_public_key
      install_file(gitolite_ssh_public_key_content, gitolite_ssh_public_key_dest_path, '644') do
        logger.error("Failed to install Redmine Git Hosting mirroring SSH public key : #{e.output}")
      end
    end


    def install_private_key
      install_file(gitolite_ssh_private_key_content, gitolite_ssh_private_key_dest_path, '600') do
        logger.error("Failed to install Redmine Git Hosting mirroring SSH private key : #{e.output}")
      end
    end


    def install_mirroring_script
      install_file(mirroring_script_content, RedmineGitHosting::Config.gitolite_mirroring_script, '700') do
        logger.error("Failed to install Redmine Git Hosting mirroring script : #{e.output}")
      end
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def mirroring_script_content
        [
          '#!/bin/sh', "\n",
          'exec', 'ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-i', gitolite_ssh_private_key_dest_path, '"$@"',
          "\n"
        ].join(' ')
      end


      def gitolite_ssh_public_key_content
        File.read(gitolite_ssh_public_key)
      rescue => e
        nil
      end


      def gitolite_ssh_private_key_content
        File.read(gitolite_ssh_private_key)
      rescue => e
        nil
      end


      def gitolite_ssh_public_key_dest_path
        File.join(gitolite_home_dir, '.ssh', "#{GITOLITE_MIRRORING_KEYS_NAME}.pub")
      end


      def gitolite_ssh_private_key_dest_path
        File.join(gitolite_home_dir, '.ssh', GITOLITE_MIRRORING_KEYS_NAME)
      end


      def install_file(source, destination, perms, &block)
        RedmineGitHosting::Commands.sudo_install_file(source, destination, perms)
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        yield
        false
      end

  end
end
