module RedmineGitHosting::Config

  module Mirroring

    ###############################
    ##                           ##
    ##          MIRRORS          ##
    ##                           ##
    ###############################

    GITOLITE_MIRRORING_KEYS_NAME = 'redmine_gitolite_admin_id_rsa_mirroring'

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def mirroring_public_key
        begin
          format_mirror_key(gitolite_ssh_public_key_content)
        rescue => e
          logger.error("Error while loading mirroring public key : #{e.output}")
          nil
        end
      end


      @mirroring_keys_installed = false

      def mirroring_keys_installed?(opts = {})
        @mirroring_keys_installed = false if opts.has_key?(:reset) && opts[:reset] == true

        if !@mirroring_keys_installed
          logger.info('Installing Redmine Gitolite mirroring SSH keys ...')

          if install_private_key && install_public_key && install_mirroring_script
            logger.info('Done !')
            @mirroring_keys_installed = true
          else
            @mirroring_keys_installed = false
          end
        end

        return @mirroring_keys_installed
      end


      def gitolite_mirroring_script
        File.join(gitolite_home_dir, '.ssh', 'run_gitolite_admin_ssh')
      end


      private


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


        def gitolite_ssh_private_key_dest_path
          File.join(gitolite_home_dir, '.ssh', GITOLITE_MIRRORING_KEYS_NAME)
        end


        def gitolite_ssh_public_key_dest_path
          File.join(gitolite_home_dir, '.ssh', "#{GITOLITE_MIRRORING_KEYS_NAME}.pub")
        end


        def install_private_key
          RedmineGitHosting::Commands.sudo_install_file(gitolite_ssh_private_key_content, gitolite_ssh_private_key_dest_path, '600')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Failed to install Redmine Git Hosting mirroring SSH private key : #{e.output}")
          false
        end


        def install_public_key
          RedmineGitHosting::Commands.sudo_install_file(gitolite_ssh_public_key_content, gitolite_ssh_public_key_dest_path, '644')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Failed to install Redmine Git Hosting mirroring SSH public key : #{e.output}")
          false
        end


        def install_mirroring_script
          RedmineGitHosting::Commands.sudo_install_file(mirroring_script_content, gitolite_mirroring_script, '700')
        rescue RedmineGitHosting::Error::GitoliteCommandException => e
          logger.error("Failed to install Redmine Git Hosting mirroring script : #{e.output}")
          false
        end


        def mirroring_script_content
          [
            '#!/bin/sh', "\n",
            'exec', 'ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-i', gitolite_ssh_private_key_dest_path, '"$@"',
            "\n"
          ].join(' ')
        end


        def format_mirror_key(key)
          key = key.chomp.strip
          key.split(/[\t ]+/)[0].to_s + ' ' + key.split(/[\t ]+/)[1].to_s
        end

    end

  end
end
