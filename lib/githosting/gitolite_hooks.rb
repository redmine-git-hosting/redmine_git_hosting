module GitHosting

  class GitoliteHooks

    def self.check_hooks_installed
      check_hook_file_installed("post-receive.redmine_gitolite.rb") && check_hook_dir_installed && check_hook_file_installed("post-receive.mail_notifications.sh")
    end


    @@check_hooks_installed_stamp = {}
    @@check_hooks_installed_cached = {}
    @@post_receive_hook_path = {}

    def self.check_hook_file_installed(hook_file)
      hook_name = hook_file.split('.')[1].to_sym
      logger.info "Installing hook '#{hook_name}' => '#{hook_file}'"

      if not @@check_hooks_installed_cached[hook_name].nil? and (Time.new - @@check_hooks_installed_stamp[hook_name] <= 1)
        return @@check_hooks_installed_cached[hook_name]
      end

      gitolite_command = get_gitolite_command

      if gitolite_command.nil?
        logger.error "Unable to find Gitolite version, cannot install '#{hook_file}' hook file !"
        @@check_hooks_installed_stamp[hook_name] = Time.new
        @@check_hooks_installed_cached[hook_name] = false
        return @@check_hooks_installed_cached[hook_name]
      end

      if hook_name == :redmine_gitolite
        @@post_receive_hook_path[hook_name] ||= File.join(gitolite_hooks_dir, 'post-receive')
      else
        @@post_receive_hook_path[hook_name] ||= File.join(gitolite_hooks_dir, 'post-receive.d', "#{hook_name}")
      end

      logger.info "Hook destination path : '#{@@post_receive_hook_path[hook_name]}'"

      post_receive_exists = (%x[#{GitHosting.shell_cmd_runner} test -r '#{@@post_receive_hook_path[hook_name]}' && echo 'yes' || echo 'no']).match(/yes/)
      post_receive_length_is_zero = false
      if post_receive_exists
        post_receive_length_is_zero= "0" == (%x[echo 'wc -c #{@@post_receive_hook_path[hook_name]}' | #{GitHosting.shell_cmd_runner} "bash" ]).chomp.strip.split(/[\t ]+/)[0]
      end

      if (!post_receive_exists) || post_receive_length_is_zero

        begin
          logger.info "Hook '#{hook_name}' not handled by us, installing it..."
          install_hook_file(hook_file, @@post_receive_hook_path[hook_name])
          logger.info "Hook '#{hook_file}' installed"

          logger.info "Running '#{gitolite_command}' on the Gitolite install..."
          GitHosting.shell %[#{GitHosting.shell_cmd_runner} #{gitolite_command}]

          update_global_hook_params

          @@check_hooks_installed_cached[hook_name] = true
        rescue => e
          logger.error "check_hooks_installed(): Problems installing hooks '#{hook_name}' and initializing Gitolite!"
          logger.error e.message
          @@check_hooks_installed_cached[hook_name] = false
        end

        @@check_hooks_installed_stamp[hook_name] = Time.new
        return @@check_hooks_installed_cached[hook_name]

      else

        contents = %x[#{GitHosting.shell_cmd_runner} 'cat #{@@post_receive_hook_path[hook_name]}']
        digest = Digest::MD5.hexdigest(contents)

        if current_hook_digest(hook_name, hook_file) == digest
          logger.info "Our '#{hook_name}' hook is already installed"
          @@check_hooks_installed_stamp[hook_name] = Time.new
          @@check_hooks_installed_cached[hook_name] = true
          return @@check_hooks_installed_cached[hook_name]
        else
          error_msg = "Hook '#{hook_name}' is already present but it's not ours!"
          logger.warn error_msg
          @@check_hooks_installed_cached[hook_name] = error_msg

          if GitHostingConf.gitolite_force_hooks_update?
            begin
              logger.info "Restoring '#{hook_name}' hook since forceInstallHook == true"
              install_hook_file(hook_file, @@post_receive_hook_path[hook_name])
              logger.info "Hook '#{hook_file}' installed"

              logger.info "Running '#{gitolite_command}' on the Gitolite install..."
              GitHosting.shell %[#{GitHosting.shell_cmd_runner} #{gitolite_command}]

              update_global_hook_params

              @@check_hooks_installed_cached[hook_name] = true
            rescue => e
              logger.error "check_hooks_installed(): Problems installing hooks '#{hook_name}' and initializing Gitolite!"
              logger.error e.message
              @@check_hooks_installed_cached[hook_name] = false
            end
          end

          @@check_hooks_installed_stamp[hook_name] = Time.new
          return @@check_hooks_installed_cached[hook_name]
        end

      end
    end


    @@check_hooks_dir_installed_cached = nil
    @@check_hooks_dir_installed_stamp = nil

    def self.check_hook_dir_installed
      if not @@check_hooks_dir_installed_cached.nil? and (Time.new - @@check_hooks_dir_installed_stamp <= 1)
        return @@check_hooks_dir_installed_cached
      end

      @@post_receive_hook_dir_path ||= File.join(gitolite_hooks_dir, 'post-receive.d')
      post_receive_dir_exists = (%x[#{GitHosting.shell_cmd_runner} test -r '#{@@post_receive_hook_dir_path}' && echo 'yes' || echo 'no']).match(/yes/)

      if (!post_receive_dir_exists)
        begin
          logger.info "Global directory 'post-receive.d' not created yet, installing it..."
          install_hook_dir("post-receive.d")
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


    @@hook_url = nil
    def self.update_global_hook_params
      cur_values = get_global_config_params

      begin
        @@hook_url ||= "http://" + File.join(GitHostingConf.my_root_url, "/githooks/post-receive")

        if cur_values["hooks.redmine_gitolite.url"] != @@hook_url
          logger.info "Updating Hook URL: #{@@hook_url}"
          GitHosting.shell %[#{GitHosting.git_cmd_runner} config --global hooks.redmine_gitolite.url "#{@@hook_url}"]
        end

        debug_hook = GitHostingConf.gitolite_hooks_debug?
        if cur_values["hooks.redmine_gitolite.debug"] != debug_hook.to_s
          logger.info "Updating Debug Hook: #{debug_hook}"
          GitHosting.shell %[#{GitHosting.git_cmd_runner} config --global --bool hooks.redmine_gitolite.debug "#{debug_hook}"]
        end

        asynch_hook = GitHostingConf.gitolite_hooks_are_asynchronous?
        if cur_values["hooks.redmine_gitolite.asynch"] != asynch_hook.to_s
          logger.info "Updating Hooks Are Asynchronous: #{asynch_hook}"
          GitHosting.shell %[#{GitHosting.git_cmd_runner} config --global --bool hooks.redmine_gitolite.asynch "#{asynch_hook}"]
        end

      rescue => e
        logger.error "update_global_hook_params(): Problems updating hook parameters!"
        logger.error e.message
      end

    end


    def self.setup_hooks(projects = nil)
      check_hooks_installed

      if projects.nil?
        projects = Project.visible.all.select{|proj| proj.gitolite_repos.any?}
      elsif projects.instance_of? Project
        projects = [projects]
      end
      setup_hooks_params(projects)
    end


    def self.setup_hooks_params(projects=[])
      return if projects.empty?

      update_global_hook_params

      local_config_map = get_local_config_map
      projects.each do |project|
        project.gitolite_repos.each do |repo|
          setup_hooks_for_repository(repo, local_config_map[GitHosting.repository_path(repo)])
        end
      end
    end


    private


    def self.logger
      return GitHosting.logger
    end


    def self.get_gitolite_command
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


    def self.gitolite_hooks_dir
      return '~/.gitolite/hooks/common'
    end


    @@cached_hooks_dir = nil
    def self.package_hooks_dir
      @@cached_hooks_dir ||= File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'contrib', 'hooks')
    end


    @@cached_hook_digest = {}
    def self.current_hook_digest(hook_name, hook_file, recreate = false)
      if @@cached_hook_digest[hook_name].nil? || recreate
        logger.debug "Creating MD5 digests for '#{hook_name}' hook"
        digest = Digest::MD5.hexdigest(File.read(File.join(package_hooks_dir, hook_file)))
        logger.debug "Digest for '#{hook_name}' hook : #{digest}"
        @@cached_hook_digest[hook_name] = digest
      end
      @@cached_hook_digest[hook_name]
    end


    def self.install_hook_file(hook_file, hook_dest_path)
      begin
        hook_source_path = File.join(package_hooks_dir, hook_file)
        logger.info "Installing '#{hook_file}' in '#{hook_dest_path}'"
        GitHosting.shell %[ cat #{hook_source_path} | #{GitHosting.shell_cmd_runner} 'cat - > #{hook_dest_path}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'chown #{GitHostingConf.gitolite_user}.#{GitHostingConf.gitolite_user} #{hook_dest_path}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'chmod 700 #{hook_dest_path}']
      rescue => e
        logger.error "install_hook(): Problems installing hook from #{hook_source_path} to #{hook_dest_path}."
        logger.error e.message
      end
    end


    def self.install_hook_dir(hooks_dir)
      begin
        dest_dir = File.join(gitolite_hooks_dir, hooks_dir)
        logger.info "Installing hook directory '#{hooks_dir}' to '#{dest_dir}'"
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'mkdir -p #{dest_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'chown -R #{GitHostingConf.gitolite_user}.#{GitHostingConf.gitolite_user} #{dest_dir}']
        GitHosting.shell %[#{GitHosting.shell_cmd_runner} 'chmod 700 #{dest_dir}']
      rescue => e
        logger.error "install_hooks_dir(): Problems installing hook directory to #{dest_dir}"
        logger.error e.message
      end
    end


    # Return a hash with all of the local config parameters for all existing repositories.  We do this with a single sudo call to find.
    def self.get_local_config_map
      local_config_map = Hash.new{|hash, key| hash[key] = {}}  # default -- empty hash

      lines = %x[#{GitHosting.shell_cmd_runner} 'find #{GitHostingConf.gitolite_global_storage_dir} -type d -name "*.git" -prune -print -exec git config -f {}/config --get-regexp hooks.redmine_gitolite \\;'].chomp.split("\n")
      filesplit = /(\.\/)*(#{GitHostingConf.gitolite_global_storage_dir}.*?[^\/]+\.git)/
      cur_repo_path = nil
      lines.each do |nextline|
        if filesplit =~ nextline
          cur_repo_path = $2
        elsif cur_repo_path
          pair = nextline.split(' ')
          local_config_map[cur_repo_path][pair[0]] = (pair[1]||"")
        end
      end
      local_config_map
    end


    # Return a hash with local config parameters for a single repository
    def self.get_local_config_params(repo)
      value_hash = {}
      repo_path = GitHosting.repository_path(repo)
      params = %x[#{GitHosting.git_cmd_runner} config -f '#{repo_path}/config' --get-regexp hooks.redmine_gitolite].split("\n").each do |valuepair|
        pair = valuepair.split(' ')
        value_hash[pair[0]]=(pair[1]||"")
      end
      value_hash
    end


    # Return a hash with global config parameters.
    def self.get_global_config_params
      begin
        value_hash = {}
        GitHosting.shell %x[#{GitHosting.git_cmd_runner} config -f '.gitconfig' --get-regexp hooks.redmine_gitolite].split("\n").each do |valuepair|
          pair = valuepair.split(' ')
          value_hash[pair[0]] = pair[1]
        end
        value_hash
      rescue => e
        logger.error "get_global_config_params(): Problems to retrieve Gitolite hook parameters in Gitolite config"
        logger.error e.message
      end
    end


    def self.setup_hooks_for_repository(repo, value_hash = nil)
      # if no value_hash given, go fetch
      value_hash = get_local_config_params(repo) if value_hash.nil?
      hook_key   = repo.extra.key
      repo_path  = GitHosting.repository_path(repo)
      repo_name  = GitHosting.repository_name(repo)

      if value_hash["hooks.redmine_gitolite.key"] != hook_key || value_hash["hooks.redmine_gitolite.projectid"] != repo.project.identifier || GitHosting.multi_repos? && (value_hash["hooks.redmine_gitolite.repositoryid"] != (repo.identifier || ""))
        if value_hash["hooks.redmine_gitolite.key"]
          logger.info "Repairing hooks parameters for repository '#{repo_name}'"
        else
          logger.info "Setting up hooks parameters for repository '#{repo_name}'"
        end

        begin
          GitHosting.shell %[#{GitHosting.git_cmd_runner} --git-dir='#{repo_path}' config hooks.redmine_gitolite.key "#{hook_key}"]
          GitHosting.shell %[#{GitHosting.git_cmd_runner} --git-dir='#{repo_path}' config hooks.redmine_gitolite.projectid "#{repo.project.identifier}"]
          if GitHosting.multi_repos?
            GitHosting.shell %[#{GitHosting.git_cmd_runner} --git-dir='#{repo_path}' config hooks.redmine_gitolite.repositoryid "#{repo.identifier||''}"]
          end
        rescue => e
          logger.error "setup_hooks_for_repository(#{repo.git_label}) failed!"
          logger.error e.message
        end
        logger.info "Done !"
      end
    end

  end
end
