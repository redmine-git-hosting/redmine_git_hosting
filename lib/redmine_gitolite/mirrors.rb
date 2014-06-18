module RedmineGitolite

  class Mirrors

    GITOLITE_MIRRORING_KEYS_NAME   = "redmine_gitolite_admin_id_rsa_mirroring"


    def self.logger
      RedmineGitolite::Log.get_logger(:global)
    end


    def self.gitolite_ssh_private_key
      RedmineGitolite::Config.get_setting(:gitolite_ssh_private_key)
    end


    def self.gitolite_ssh_public_key
      RedmineGitolite::Config.get_setting(:gitolite_ssh_public_key)
    end


    def self.gitolite_home_dir
      RedmineGitolite::GitoliteWrapper.gitolite_home_dir
    end


    def self.gitolite_ssh_private_key_path
      File.join(gitolite_home_dir, '.ssh', GITOLITE_MIRRORING_KEYS_NAME)
    end


    def self.gitolite_ssh_public_key_path
      File.join(gitolite_home_dir, '.ssh', "#{GITOLITE_MIRRORING_KEYS_NAME}.pub")
    end


    def self.gitolite_mirroring_script_path
      File.join(gitolite_home_dir, '.ssh', 'run_gitolite_admin_ssh')
    end


    @@mirroring_public_key = nil

    def self.mirroring_public_key
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

    def self.mirroring_keys_installed?(opts = {})
      @@mirroring_keys_installed = false if opts.has_key?(:reset) && opts[:reset] == true

      if !@@mirroring_keys_installed
        logger.info { "Installing Redmine Gitolite mirroring SSH keys ..." }

        key_path = File.join(gitolite_home_dir, '.ssh', GITOLITE_MIRRORING_KEYS_NAME)
        command = ['#!/bin/sh', "\n", 'exec', 'ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=no', '-i', key_path, '"$@"'].join(' ')

        begin
          GitoliteWrapper.pipe_sudo('cat', gitolite_ssh_private_key, "'cat - > #{gitolite_ssh_private_key_path}'")
          GitoliteWrapper.pipe_sudo('cat', gitolite_ssh_public_key,  "'cat - > #{gitolite_ssh_public_key_path}'")

          GitoliteWrapper.sudo_chmod('600', gitolite_ssh_private_key_path)
          GitoliteWrapper.sudo_chmod('644', gitolite_ssh_public_key_path)

          GitoliteWrapper.pipe_sudo('echo', "'#{command}'", "'cat - > #{gitolite_mirroring_script_path}'")

          GitoliteWrapper.sudo_chmod('700', gitolite_mirroring_script_path)

          logger.info { "Done !" }

          @@mirroring_keys_installed = true
        rescue GitHosting::GitHostingException => e
          logger.error { "Failed installing Redmine Gitolite mirroring SSH keys !" }
          @@mirroring_keys_installed = false
        end
      end

      return @@mirroring_keys_installed
    end

  end
end
