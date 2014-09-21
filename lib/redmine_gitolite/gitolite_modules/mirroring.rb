module RedmineGitolite::GitoliteModules

  module Mirroring

    ###############################
    ##                           ##
    ##          MIRRORS          ##
    ##                           ##
    ###############################

    GITOLITE_MIRRORING_KEYS_NAME   = "redmine_gitolite_admin_id_rsa_mirroring"

    class << self
      def included(receiver)
        receiver.send(:extend, ClassMethods)
      end
    end


    module ClassMethods

      def gitolite_ssh_private_key_dest_path
        File.join('$HOME', '.ssh', GITOLITE_MIRRORING_KEYS_NAME)
      end


      def gitolite_ssh_public_key_dest_path
        File.join('$HOME', '.ssh', "#{GITOLITE_MIRRORING_KEYS_NAME}.pub")
      end


      def gitolite_mirroring_script_dest_path
        File.join('$HOME', '.ssh', 'run_gitolite_admin_ssh')
      end


      @@mirroring_public_key = nil

      def mirroring_public_key
        if @@mirroring_public_key.nil?
          begin
            public_key = File.read(gitolite_ssh_public_key).chomp.strip
            @@mirroring_public_key = public_key.split(/[\t ]+/)[0].to_s + " " + public_key.split(/[\t ]+/)[1].to_s
          rescue => e
            logger.error { "Error while loading mirroring public key : #{e.output}" }
            @@mirroring_public_key = nil
          end
        end

        return @@mirroring_public_key
      end


      @@mirroring_keys_installed = false

      def mirroring_keys_installed?(opts = {})
        @@mirroring_keys_installed = false if opts.has_key?(:reset) && opts[:reset] == true

        if !@@mirroring_keys_installed
          logger.info { "Installing Redmine Gitolite mirroring SSH keys ..." }

          if (install_private_key && install_public_key && install_mirroring_script)
            logger.info { "Done !" }
            @@mirroring_keys_installed = true
          else
            logger.error { "Failed to install Redmine Gitolite mirroring SSH keys !" }
            @@mirroring_keys_installed = false
          end
        end

        return @@mirroring_keys_installed
      end


      def install_private_key
        sudo_install_file(File.read(gitolite_ssh_private_key), gitolite_ssh_private_key_dest_path, '600')
      end


      def install_public_key
        sudo_install_file(File.read(gitolite_ssh_public_key), gitolite_ssh_public_key_dest_path, '644')
      end


      def install_mirroring_script
        command = ['#!/bin/sh', "\n", 'exec', 'ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-i', gitolite_ssh_private_key_dest_path, '"$@"', "\n"].join(' ')
        sudo_install_file(command, gitolite_mirroring_script_dest_path, '700')
      end

    end

  end
end
