require 'digest/md5'

module RedmineGitolite

  class Hooks

    GITOLITE_HOOKS_DIR    = '~/.gitolite/hooks/common'
    POST_RECEIVE_HOOK_DIR = File.join(GITOLITE_HOOKS_DIR, 'post-receive.d')
    PACKAGE_HOOKS_DIR     = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'contrib', 'hooks')
    POST_RECEIVE_HOOKS    = {
      'post-receive.redmine_gitolite.rb'   => { :source => 'post-receive.redmine_gitolite.rb',   :destination => 'post-receive',                      :executable => true },
      'post-receive.git_multimail.py'      => { :source => 'post-receive.git_multimail.py',      :destination => 'post-receive.d/git_multimail.py',   :executable => false },
      'post-receive.mail_notifications.py' => { :source => 'post-receive.mail_notifications.py', :destination => 'post-receive.d/mail_notifications', :executable => true }
    }


    def check_install
      installed = {}

      installed['global_hook_params'] = update_global_hook_params
      installed['post-receive.d'] = check_hook_dir_installed

      POST_RECEIVE_HOOKS.each do |hook|
        installed[hook[0]] = check_hook_file_installed(hook)
      end

      return installed
    end


    def update_global_hook_params
      cur_values = get_global_config_params

      begin
        redmine_url = RedmineGitolite::Config.gitolite_hooks_url
        if cur_values["redmineGitolite.redmineUrl"] != redmine_url
          logger.info "Update Git hooks global parameter : redmineUrl (#{redmine_url})"
          GitHosting.shell %[#{GitHosting.git_cmd_runner} config --global redmineGitolite.redmineUrl "#{redmine_url}"]
        end

        debug_hook = RedmineGitolite::Config.get_setting(:gitolite_hooks_debug, true)
        if cur_values["redmineGitolite.debugMode"] != debug_hook.to_s
          logger.info "Update Git hooks global parameter : debugMode (#{debug_hook})"
          GitHosting.shell %[#{GitHosting.git_cmd_runner} config --global --bool redmineGitolite.debugMode "#{debug_hook}"]
        end

        async_hook = RedmineGitolite::Config.get_setting(:gitolite_hooks_are_asynchronous, true)
        if cur_values["redmineGitolite.asyncMode"] != async_hook.to_s
          logger.info "Update Git hooks global parameter : asyncMode (#{async_hook})"
          GitHosting.shell %[#{GitHosting.git_cmd_runner} config --global --bool redmineGitolite.asyncMode "#{async_hook}"]
        end

        return true
      rescue => e
        logger.error "update_global_hook_params(): Problems updating Git hooks global parameters!"
        logger.error e.message
        return false
      end
    end


    private


    def logger
      return GitHosting.logger
    end


    # Return a hash with global config parameters.
    def get_global_config_params
      begin
        value_hash = {}
        GitHosting.shell %x[#{GitHosting.git_cmd_runner} config -f '.gitconfig' --get-regexp redmineGitolite].split("\n").each do |valuepair|
          pair = valuepair.split(' ')
          value_hash[pair[0]] = pair[1]
        end
        return value_hash
      rescue => e
        logger.error "get_global_config_params(): Problems to retrieve Gitolite hook parameters in Gitolite config"
        logger.error e.message
      end
    end



    ###############################
    ##                           ##
    ##         HOOKS DIR         ##
    ##                           ##
    ###############################


    @@check_hooks_dir_installed_cached = nil
    @@check_hooks_dir_installed_stamp = nil


    def check_hook_dir_installed
      if !@@check_hooks_dir_installed_cached.nil? && (Time.new - @@check_hooks_dir_installed_stamp <= 1)
        return @@check_hooks_dir_installed_cached
      end

      post_receive_dir_exists = (%x[#{GitHosting.shell_cmd_runner} test -r '#{POST_RECEIVE_HOOK_DIR}' && echo 'yes' || echo 'no']).match(/yes/)

      if (!post_receive_dir_exists)
        logger.info "Global directory 'post-receive.d' not created yet, installing it..."

        begin
          install_hooks_dir("post-receive.d")
          logger.info "Global directory 'post-receive.d' installed"

          @@check_hooks_dir_installed_cached = true
        rescue => e
          logger.error "check_hook_dir_installed(): Problems installing hook dir !"
          logger.error e.message

          @@check_hooks_dir_installed_cached = false
        end

        @@check_hooks_dir_installed_stamp = Time.new
        return @@check_hooks_dir_installed_cached
      else
        logger.info "Global directory 'post-receive.d' is already present, will not touch it !"
        @@check_hooks_dir_installed_cached = true
        @@check_hooks_dir_installed_stamp = Time.new
        return @@check_hooks_dir_installed_cached
      end
    end


    def install_hooks_dir(hooks_dir)
      dest_dir = File.join(GITOLITE_HOOKS_DIR, hooks_dir)
      logger.info "Installing hook directory '#{hooks_dir}' to '#{dest_dir}'"

      begin
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'mkdir -p #{dest_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'chmod 755 #{dest_dir}']
      rescue => e
        logger.error "install_hooks_dir(): Problems installing hooks directory in #{dest_dir}"
        logger.error e.message
      end
    end


    ###############################
    ##                           ##
    ##         HOOK FILES        ##
    ##                           ##
    ###############################


    @@check_hooks_installed_stamp = {}
    @@check_hooks_installed_cached = {}
    @@post_receive_hook_path = {}


    def check_hook_file_installed(hook)

      hook_name = hook[0]
      hook_data = hook[1]

      if !@@check_hooks_installed_cached[hook_name].nil? && (Time.new - @@check_hooks_installed_stamp[hook_name] <= 1)
        return @@check_hooks_installed_cached[hook_name]
      end

      gitolite_command = get_gitolite_command

      if gitolite_command.nil?
        logger.error "Unable to find Gitolite version, cannot install '#{hook_name}' hook file !"
        @@check_hooks_installed_stamp[hook_name] = Time.new
        @@check_hooks_installed_cached[hook_name] = false
        return @@check_hooks_installed_cached[hook_name]
      end

      @@post_receive_hook_path[hook_name] ||= File.join(GITOLITE_HOOKS_DIR, hook_data[:destination])

      post_receive_exists = (%x[#{GitHosting.shell_cmd_runner} test -r '#{@@post_receive_hook_path[hook_name]}' && echo 'yes' || echo 'no']).match(/yes/)
      post_receive_length_is_zero = false

      if post_receive_exists
        post_receive_length_is_zero= "0" == (%x[echo 'wc -c #{@@post_receive_hook_path[hook_name]}' | #{GitHosting.shell_cmd_runner} "bash" ]).chomp.strip.split(/[\t ]+/)[0]
      end

      if (!post_receive_exists) || post_receive_length_is_zero
        logger.info "Hook '#{hook_name}' does not exist, installing it..."

        begin
          install_hook_file(hook_data)
          logger.info "Hook '#{hook_name}' installed"

          logger.info "Running '#{gitolite_command}' on the Gitolite install..."
          GitHosting.shell %[#{GitHosting.shell_cmd_runner} #{gitolite_command}]

          @@check_hooks_installed_cached[hook_name] = true
        rescue => e
          logger.error "check_hook_file_installed(): Problems installing hooks '#{hook_name}'"
          logger.error e.message
          @@check_hooks_installed_cached[hook_name] = false
        end

        @@check_hooks_installed_stamp[hook_name] = Time.new
        return @@check_hooks_installed_cached[hook_name]

      else

        contents = %x[#{GitHosting.shell_cmd_runner} 'cat #{@@post_receive_hook_path[hook_name]}']
        digest = Digest::MD5.hexdigest(contents)

        if current_hook_digest(hook_data) == digest
          logger.info "Our '#{hook_name}' hook is already installed"
          @@check_hooks_installed_stamp[hook_name] = Time.new
          @@check_hooks_installed_cached[hook_name] = true
          return @@check_hooks_installed_cached[hook_name]
        else
          error_msg = "Hook '#{hook_name}' is already present but it's not ours!"
          logger.warn error_msg
          @@check_hooks_installed_cached[hook_name] = error_msg

          if RedmineGitolite::Config.get_setting(:gitolite_force_hooks_update, true)
            logger.info "Restoring '#{hook_name}' hook since forceInstallHook == true"

            begin
              install_hook_file(hook_data)
              logger.info "Hook '#{hook_name}' installed"

              logger.info "Running '#{gitolite_command}' on the Gitolite install..."
              GitHosting.shell %[#{GitHosting.shell_cmd_runner} #{gitolite_command}]

              @@check_hooks_installed_cached[hook_name] = true
            rescue => e
              logger.error "check_hook_file_installed(): Problems installing hooks '#{hook_name}'"
              logger.error e.message
              @@check_hooks_installed_cached[hook_name] = false
            end
          end

          @@check_hooks_installed_stamp[hook_name] = Time.new
          return @@check_hooks_installed_cached[hook_name]
        end

      end
    end


    def install_hook_file(hook_data)
      source_path      = File.join(PACKAGE_HOOKS_DIR, hook_data[:source])
      destination_path = File.join(GITOLITE_HOOKS_DIR, hook_data[:destination])

      if hook_data[:executable]
        filemode = 755
      else
        filemode = 644
      end

      logger.info "Installing hook '#{source_path}' in '#{destination_path}'"

      begin
        GitHosting.shell %[ cat #{source_path} | #{GitHosting.shell_cmd_runner} 'cat - > #{destination_path}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'chmod #{filemode} #{destination_path}']
      rescue => e
        logger.error "install_hook_file(): Problems installing hook from '#{source_path}' in '#{destination_path}'"
        logger.error e.message
      end
    end


    def get_gitolite_command
      gitolite_version = GitHosting.gitolite_version
      if gitolite_version == 2
        gitolite_command = 'gl-setup'
      elsif gitolite_version == 3
        gitolite_command = 'gitolite setup'
      else
        gitolite_command = nil
      end
      return gitolite_command
    end


    def current_hook_digest(hook_data)
      hook_name   = hook_data[:source]
      source_path = File.join(PACKAGE_HOOKS_DIR, hook_data[:source])

      digest = Digest::MD5.hexdigest(File.read(source_path))
      logger.debug "Digest for '#{hook_name}' hook : #{digest}"

      return digest
    end

  end
end
