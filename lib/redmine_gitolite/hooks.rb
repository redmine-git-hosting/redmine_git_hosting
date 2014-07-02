require 'digest/md5'

module RedmineGitolite

  class Hooks

    GITOLITE_HOOKS_NAMESPACE = 'redminegitolite'

    PACKAGE_HOOKS_DIR        = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'contrib', 'hooks')

    POST_RECEIVE_HOOKS    = {
      'post-receive.redmine_gitolite.rb'   => { :source => 'post-receive.redmine_gitolite.rb',   :destination => 'post-receive',                      :executable => true },
      'post-receive.git_multimail.py'      => { :source => 'post-receive.git_multimail.py',      :destination => 'post-receive.d/git_multimail.py',   :executable => false },
      'post-receive.mail_notifications.py' => { :source => 'post-receive.mail_notifications.py', :destination => 'post-receive.d/mail_notifications', :executable => true }
    }


    attr_accessor :gitolite_hooks_url
    attr_accessor :gitolite_hooks_namespace


    def initialize
      @gitolite_command   = RedmineGitolite::GitoliteWrapper.gitolite_command
      @gitolite_hooks_url = RedmineGitolite::GitoliteWrapper.gitolite_hooks_url
      @debug_mode         = RedmineGitolite::Config.get_setting(:gitolite_hooks_debug)
      @async_mode         = RedmineGitolite::Config.get_setting(:gitolite_hooks_are_asynchronous)
      @force_hooks_update = RedmineGitolite::Config.get_setting(:gitolite_force_hooks_update)

      @gitolite_hooks_dir    = File.join('$HOME', '.gitolite', 'hooks', 'common')
      @post_receive_hook_dir = File.join(@gitolite_hooks_dir, 'post-receive.d')

      @global_hook_params   = get_git_config_params(GITOLITE_HOOKS_NAMESPACE)
      @multimailhook_params = get_git_config_params('multimailhook')

      @gitolite_hooks_namespace = GITOLITE_HOOKS_NAMESPACE
    end


    def check_install
      return [ hooks_installed?, hook_params_installed?, mailer_params_installed? ]
    end


    def hooks_installed?
      installed = {}

      installed['post-receive.d'] = check_hook_dir_installed

      POST_RECEIVE_HOOKS.each do |hook|
        installed[hook[0]] = check_hook_file_installed(hook)
      end

      return installed
    end


    def hook_params_installed?
      installed = {}

      if @global_hook_params["redmineurl"] != @gitolite_hooks_url
        installed['redmineurl'] = set_git_config_param("redmineurl", @gitolite_hooks_url)
      else
        installed['redmineurl'] = true
      end

      if @global_hook_params["debugmode"] != @debug_mode.to_s
        installed['debugmode'] = set_git_config_param("debugmode", @debug_mode.to_s)
      else
        installed['debugmode'] = true
      end

      if @global_hook_params["asyncmode"] != @async_mode.to_s
        installed['asyncmode'] = set_git_config_param("asyncmode", @async_mode.to_s)
      else
        installed['asyncmode'] = true
      end

      return installed
    end


    def mailer_params_installed?
      params = %w(mailer environment smtpAuth smtpServer smtpPort smtpUser smtpPass)
      current_params = get_mailer_params
      installed = {}

      params.each do |param|
        if @multimailhook_params[param] != current_params[param]
          installed[param] = set_git_config_param(param, current_params[param].to_s, "multimailhook")
        else
          installed[param] = true
        end
      end

      return installed
    end


    private


    def logger
      RedmineGitolite::Log.get_logger(:global)
    end


    def get_mailer_params
      params = {}

      params['environment'] = 'gitolite'

      if ActionMailer::Base.delivery_method == :smtp
        params['mailer'] = 'smtp'
      else
        params['mailer'] = 'sendmail'
      end

      auth = ActionMailer::Base.smtp_settings[:authentication]

      if auth != nil && auth != '' && auth != :none
        params['smtpAuth'] = true
      else
        params['smtpAuth'] = false
      end

      params['smtpServer'] = ActionMailer::Base.smtp_settings[:address]
      params['smtpPort']   = ActionMailer::Base.smtp_settings[:port]
      params['smtpUser']   = ActionMailer::Base.smtp_settings[:user_name] || ''
      params['smtpPass']   = ActionMailer::Base.smtp_settings[:password] || ''

      params
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

      if !hook_dir_exists?(@post_receive_hook_dir)
        logger.info { "Global hook directory '#{@post_receive_hook_dir}' not created yet, installing it..." }

        if install_hooks_dir(@post_receive_hook_dir)
          logger.info { "Global hook directory '#{@post_receive_hook_dir}' installed" }
          @@check_hooks_dir_installed_cached = true
        else
          @@check_hooks_dir_installed_cached = false
        end

        @@check_hooks_dir_installed_stamp = Time.new
      else
        logger.info { "Global hook directory '#{@post_receive_hook_dir}' is already present, will not touch it !" }
        @@check_hooks_dir_installed_cached = true
        @@check_hooks_dir_installed_stamp = Time.new
      end

      return @@check_hooks_dir_installed_cached
    end


    def install_hooks_dir(hook_dir)
      logger.info { "Installing hook directory '#{hook_dir}'" }

      begin
        GitoliteWrapper.sudo_mkdir('-p', hook_dir)
        GitoliteWrapper.sudo_chmod('755', hook_dir)
        return true
      rescue GitHosting::GitHostingException => e
        logger.error { "Problems installing hook directory '#{hook_dir}'" }
        return false
      end
    end


    def hook_dir_exists?(hook_dir)
      begin
        GitoliteWrapper.sudo_dir_exists?(hook_dir)
      rescue GitHosting::GitHostingException => e
        return false
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

      if @gitolite_command.nil?
        logger.error { "Unable to find Gitolite version, cannot install '#{hook_name}' hook file !" }
        @@check_hooks_installed_stamp[hook_name] = Time.new
        @@check_hooks_installed_cached[hook_name] = false
        return @@check_hooks_installed_cached[hook_name]
      end

      @@post_receive_hook_path[hook_name] ||= File.join(@gitolite_hooks_dir, hook_data[:destination])

      if !hook_file_exists?(@@post_receive_hook_path[hook_name])

        logger.info { "Hook '#{hook_name}' does not exist, installing it ..." }

        if install_hook_file(hook_data)
          logger.info { "Hook '#{hook_name}' installed" }
          logger.info { "Running '#{@gitolite_command.join(' ')}' on the Gitolite install ..." }

          if update_gitolite
            @@check_hooks_installed_cached[hook_name] = true
          else
            @@check_hooks_installed_cached[hook_name] = false
          end
        else
          @@check_hooks_installed_cached[hook_name] = false
        end

        @@check_hooks_installed_stamp[hook_name] = Time.new
        return @@check_hooks_installed_cached[hook_name]

      else

        content = GitoliteWrapper.sudo_capture('eval', 'cat', @@post_receive_hook_path[hook_name])
        digest  = Digest::MD5.hexdigest(content)

        if hook_digest(hook_data) == digest
          logger.info { "Our '#{hook_name}' hook is already installed" }
          @@check_hooks_installed_stamp[hook_name] = Time.new
          @@check_hooks_installed_cached[hook_name] = true
          return @@check_hooks_installed_cached[hook_name]

        else

          error_msg = "Hook '#{hook_name}' is already present but it's not ours!"
          logger.warn { error_msg }
          @@check_hooks_installed_cached[hook_name] = error_msg

          if @force_hooks_update
            logger.info { "Restoring '#{hook_name}' hook since forceInstallHook == true" }

            if install_hook_file(hook_data)
              logger.info { "Hook '#{hook_name}' installed" }
              logger.info { "Running '#{@gitolite_command.join(' ')}' on the Gitolite install..." }

              if update_gitolite
                @@check_hooks_installed_cached[hook_name] = true
              else
                @@check_hooks_installed_cached[hook_name] = false
              end
            else
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
      destination_path = File.join(@gitolite_hooks_dir, hook_data[:destination])

      if hook_data[:executable]
        filemode = '755'
      else
        filemode = '644'
      end

      logger.info { "Installing hook '#{source_path}' in '#{destination_path}'" }

      begin
        GitoliteWrapper.sudo_pipe("sh") do
          [ 'cat', '<<\EOF', '>' + destination_path, "\n" + File.read(source_path) + "EOF" ].join(' ')
        end
        GitoliteWrapper.sudo_chmod(filemode, destination_path)
        return true
      rescue GitHosting::GitHostingException => e
        logger.error { "Problems installing hook from '#{source_path}' in '#{destination_path}'" }
        return false
      end
    end


    def hook_file_exists?(hook_path)
      begin
        GitoliteWrapper.sudo_file_exists?(hook_path)
      rescue GitHosting::GitHostingException => e
        return false
      end
    end


    def hook_digest(hook_data)
      hook_name   = hook_data[:source]
      source_path = File.join(PACKAGE_HOOKS_DIR, hook_data[:source])

      digest = Digest::MD5.hexdigest(File.read(source_path))
      logger.debug "Digest for '#{hook_name}' hook : #{digest}"

      return digest
    end


    def update_gitolite
      begin
        GitoliteWrapper.sudo_shell(*@gitolite_command)
        return true
      rescue GitHosting::GitHostingException => e
        return false
      end
    end


    ###############################
    ##                           ##
    ##         GIT PARAMS        ##
    ##                           ##
    ###############################


    # Return a hash with global config parameters.
    def get_git_config_params(namespace)
      begin
        params = GitoliteWrapper.sudo_capture('git', 'config', '-f', '.gitconfig', '--get-regexp', namespace).split("\n")
      rescue GitHosting::GitHostingException => e
        logger.error { "Problems to retrieve Gitolite hook parameters in Gitolite config 'namespace : #{namespace}'" }
        params = []
      end

      value_hash = {}

      params.each do |value_pair|
        global_key = value_pair.split(' ')[0]
        value      = value_pair.split(' ')[1]
        key        = global_key.split('.')[1]
        value_hash[key] = value
      end

      return value_hash
    end


    def set_git_config_param(key, value, namespace = GITOLITE_HOOKS_NAMESPACE)
      key = gitconfig_prefix(key, namespace)

      return unset_git_config_param(key) if value == ''

      logger.info { "Set Git hooks global parameter : #{key} (#{value})" }

      begin
        GitoliteWrapper.sudo_capture('git', 'config', '--global', key, value)
        return true
      rescue GitHosting::GitHostingException => e
        logger.error { "Error while setting Git hooks global parameter : #{key} (#{value})" }
        logger.error { e.output }
        return false
      end
    end


    def unset_git_config_param(key)
      logger.info { "Unset Git hooks global parameter : #{key}" }

      begin
        _, _, code = GitoliteWrapper.sudo_shell('git', 'config', '--global', '--unset', key)
        return true
      rescue GitHosting::GitHostingException => e
        if code == 5
          return true
        else
          logger.error { "Error while removing Git hooks global parameter : #{key}" }
          logger.error { e.output }
          return false
        end
      end
    end


    # Returns the global gitconfig prefix for
    # a config with that given key under the
    # hooks namespace.
    #
    def gitconfig_prefix(key, namespace)
      [namespace, '.', key].join
    end

  end
end
