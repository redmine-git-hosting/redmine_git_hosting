require 'digest/md5'

module GitHosting

  class GitAdapterHooks

    def self.check_hooks_installed
        files_installed = check_hook_files_installed
        dir_installed = check_hook_dir_installed
        files_installed && dir_installed
    end

    @@check_hooks_installed_stamp = nil
    @@check_hooks_installed_cached = nil
    @@post_receive_hook_path = nil
    
    def self.check_hook_files_installed
      if not @@check_hooks_installed_cached.nil? and (Time.new - @@check_hooks_installed_stamp <= 0.5)
        return @@check_hooks_installed_cached
      end

      @@post_receive_hook_path ||= File.join(gitolite_hooks_dir, 'post-receive')
      post_receive_exists = (%x[#{GitHosting.git_user_runner} test -r '#{@@post_receive_hook_path}' && echo 'yes' || echo 'no']).match(/yes/)
      post_receive_length_is_zero = false
      if post_receive_exists
        post_receive_length_is_zero= "0" == (%x[echo 'wc -c  #{@@post_receive_hook_path}' | #{GitHosting.git_user_runner} "bash" ]).chomp.strip.split(/[\t ]+/)[0]
      end

      if (!post_receive_exists) || post_receive_length_is_zero
        begin
          logger.info "[GitHosting] \"post-receive\" not handled by gitolite, installing it..."
          install_hook("post-receive.redmine_gitolite.rb")
          logger.info "[GitHosting] \"post-receive.redmine_gitolite\ installed"
          logger.info "[GitHosting] Running \"gl-setup\" on the gitolite install..."
          GitHosting.shell %[#{GitHosting.git_user_runner} gl-setup]
          update_global_hook_params
          logger.info "[GitHosting] Finished installing hooks in the gitolite install..."
          @@check_hooks_installed_stamp = Time.new
          @@check_hooks_installed_cached = true
        rescue
          logger.error "[GitHosting] check_hooks_files_installed(): Problems installing hooks and initializing gitolite!"
        end
        return @@check_hooks_installed_cached
      else
        contents = %x[#{GitHosting.git_user_runner} 'cat #{@@post_receive_hook_path}']
        digest = Digest::MD5.hexdigest(contents)

        logger.debug "[GitHosting] Installed hook digest: #{digest}"
        if rgh_hook_digest == digest
          logger.info "[GitHosting] Our hook is already installed"
          @@check_hooks_installed_stamp = Time.new
          @@check_hooks_installed_cached = true
          return @@check_hooks_installed_cached
        else
          error_msg = "[GitHosting] \"post-receive\" is already present but it's not ours!"
          logger.warn error_msg
          @@check_hooks_installed_cached = error_msg
          if GitHostingConf.git_force_hooks_update?
            begin
              logger.info "[GitHosting] Restoring \"post-receive\" hook since forceInstallHook == true"
              install_hook("post-receive.redmine_gitolite.rb")
              logger.info "[GitHosting] \"post-receive.redmine_gitolite\ installed"
              logger.info "[GitHosting] Running \"gl-setup\" on the gitolite install..."
              GitHosting.shell %[#{GitHosting.git_user_runner} gl-setup]
              update_global_hook_params
              logger.info "[GitHosting] Finished installing hooks in the gitolite install..."
              @@check_hooks_installed_cached = true
            rescue
              logger.error "[GitHosting] check_hooks_files_installed(): Problems installing hooks and initializing gitolite!"
            end
          end
          @@check_hooks_installed_stamp = Time.new
          return @@check_hooks_installed_cached
        end
      end
    end

    @@check_hooks_dir_installed_cached = nil
    @@check_hooks_dir_installed_stamp = nil
    def self.check_hook_dir_installed
        if not @@check_hooks_dir_installed_cached.nil? and (Time.new - @@check_hooks_dir_installed_stamp <= 0.5)
            return @@check_hooks_dir_installed_cached
        end

        @@post_receive_hook_dir_path ||= File.join(gitolite_hooks_dir, 'post-receive.d')
        post_receive_dir_exists = (%x[#{GitHosting.git_user_runner} test -r '#{@@post_receive_hook_dir_path}' && echo 'yes' || echo 'no']).match(/yes/)

        if (!post_receive_dir_exists)
            begin
                logger.info "[GitHosting] \"post-receive.d\" folder not yet created, installing it..."
                install_hook_dir("post-receive.d")
                logger.info "[GitHosting] \"post-receive.d installed"
                logger.info "[GitHosting] Running \"gl-setup\" on the gitolite install..."
                GitHosting.shell %[#{GitHosting.git_user_runner} gl-setup]
                logger.info "[GitHosting] Finished installing global hook directory in the gitolite install..."
                @@check_hooks_dir_installed_stamp = Time.new
                @@check_hooks_dir_installed_cached = true
            rescue
                logger.error "[GitHosting] check_hook_dir_installed(): Problems installing hooks and initializing gitolite!"
            end
            return @@check_hooks_dir_installed_cached
        else
            error_msg = "[GitHosting] Global \"post-receive.d\" directory is already present, will not touch it!"
            logger.warn error_msg
            @@check_hooks_dir_installed_cached = error_msg
            begin
                logger.info "[GitHosting] Running \"gl-setup\" on the gitolite install..."
                GitHosting.shell %[#{GitHosting.git_user_runner} gl-setup]
                logger.info "[GitHosting] Finished installing hook directory in the gitolite install..."
                @@check_hooks_dir_installed_cached = true
            rescue
                logger.error "[GitHosting] check_hook_dir_installed(): Problems installing hook directory and initializing gitolite!"
            end
            @@check_hooks_dir_installed_stamp = Time.new
            return @@check_hooks_dir_installed_cached
        end
    end

    def self.setup_hooks(projects=nil)
      check_hooks_installed

      if projects.nil?
        projects = Project.visible.all.select{|proj| proj.gl_repos.any?}
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
        project.gl_repos.each do |repo|
          setup_hooks_for_repository(repo, local_config_map[GitHosting.repository_path(repo)])
        end
      end
    end

    @@hook_url = nil
    def self.update_global_hook_params
      cur_values = get_global_config_params
      begin
        @@hook_url ||= "http://" + File.join(GitHosting.my_root_url,"/githooks/post-receive")
        if cur_values["hooks.redmine_gitolite.url"] != @@hook_url
          logger.warn "[GitHosting] Updating Hook URL: #{@@hook_url}"
          GitHosting.shell %[#{GitHosting.git_exec} config --global hooks.redmine_gitolite.url "#{@@hook_url}"]
        end

        debug_hook = GitHostingConf.git_hooks_debug?
        if cur_values["hooks.redmine_gitolite.debug"] != debug_hook
          logger.warn "[GitHosting] Updating Debug Hook: #{debug_hook}"
          GitHosting.shell %[#{GitHosting.git_exec} config --global --bool hooks.redmine_gitolite.debug "#{debug_hook}"]
        end

        asynch_hook = GitHostingConf.git_hooks_are_asynchronous?
        if cur_values["hooks.redmine_gitolite.asynch"] != asynch_hook
          logger.warn "[GitHosting] Updating Hooks Are Asynchronous: #{asynch_hook}"
          GitHosting.shell %[#{GitHosting.git_exec} config --global --bool hooks.redmine_gitolite.asynch "#{asynch_hook}"]
        end
      rescue
        logger.error "[GitHosting] update_global_hook_params(): Problems updating hook parameters!"
      end
    end

    private

    def self.logger
      return GitHosting::logger
    end

    def self.gitolite_hooks_dir
      return '~/.gitolite/hooks/common'
    end

    @@cached_hooks_dir = nil
    def self.package_hooks_dir
      @@cached_hooks_dir ||= File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'contrib', 'hooks')
    end

    @@cached_hook_digest = nil
    def self.rgh_hook_digest(recreate=false)
      if @@cached_hook_digest.nil? || recreate
        logger.info "[GitHosting] Creating MD5 digests for Redmine Git Hosting hook"
        hook_file = "post-receive.redmine_gitolite.rb"
        digest = Digest::MD5.hexdigest(File.read(File.join(package_hooks_dir, hook_file)))
        logger.info "[GitHosting] Digest for #{hook_file}: #{digest}"
        @@cached_hook_digest = digest
      end
      @@cached_hook_digest
    end

    def self.install_hook_dir(hooks_dir)
        begin
        dest_dir = File.join(gitolite_hooks_dir, hooks_dir)
        logger.info "[GitHosting] Installing hook directory to #{dest_dir}"
        GitHosting.shell %[#{GitHosting.git_user_runner} 'mkdir -p #{dest_dir}']
        GitHosting.shell %[#{GitHosting.git_user_runner} 'chown #{git_user} #{dest_dir}']
        GitHosting.shell %[#{GitHosting.git_user_runner} 'chmod 700 #{dest_dir}']
        rescue
        logger.error "[GitHosting] install_hooks_dir(): Problems installing hook directory to #{dest_dir}"
        end
    end

    def self.install_hook(hook_name)
      begin
        hook_source_path = File.join(package_hooks_dir, hook_name)
        hook_dest_path = File.join(gitolite_hooks_dir, hook_name.split('.')[0])
        logger.info "[GitHosting] Installing \"#{hook_name}\" from #{hook_source_path} to #{hook_dest_path}"
        git_user = GitHostingConf.git_user
        GitHosting.shell %[ cat #{hook_source_path} |  #{GitHosting.git_user_runner} 'cat - > #{hook_dest_path}']
        GitHosting.shell %[#{GitHosting.git_user_runner} 'chown #{git_user} #{hook_dest_path}']
        GitHosting.shell %[#{GitHosting.git_user_runner} 'chmod 700 #{hook_dest_path}']
      rescue
        logger.error "[GitHosting] install_hook(): Problems installing hook from #{hook_source_path} to #{hook_dest_path}."
      end
    end

    # Return a hash with all of the local config parameters for all existing repositories.  We do this with a single sudo call to find.
    def self.get_local_config_map
      local_config_map=Hash.new{|hash, key| hash[key] = {}}  # default -- empty hash

      lines = %x[#{GitHosting.git_user_runner} 'find #{GitHostingConf.repository_base} -type d -name "*.git" -prune -print -exec git config -f {}/config --get-regexp hooks.redmine_gitolite \\;'].chomp.split("\n")
      filesplit = /(\.\/)*(#{GitHostingConf.repository_base}.*?[^\/]+\.git)/
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
      params = %x[#{GitHosting.git_exec} config -f '#{repo_path}/config' --get-regexp hooks.redmine_gitolite].split("\n").each do |valuepair|
        pair = valuepair.split(' ')
        value_hash[pair[0]]=(pair[1]||"")
      end
      value_hash
    end

    # Return a hash with global config parameters.
    def self.get_global_config_params
      value_hash = {}
      params = %x[#{GitHosting.git_exec} config -f '.gitconfig' --get-regexp hooks.redmine_gitolite].split("\n").each do |valuepair|
        pair = valuepair.split(' ')
        value_hash[pair[0]]=pair[1]
      end
      value_hash
    end

    def self.setup_hooks_for_repository(repo,value_hash=nil)
      # if no value_hash given, go fetch
      value_hash = get_local_config_params(repo) if value_hash.nil?
      hook_key = repo.extra.key
      if value_hash["hooks.redmine_gitolite.key"] != hook_key || value_hash["hooks.redmine_gitolite.projectid"] != repo.project.identifier || GitHosting.multi_repos? && (value_hash["hooks.redmine_gitolite.repositoryid"] != (repo.identifier || ""))
        if value_hash["hooks.redmine_gitolite.key"]
          logger.info "[GitHosting] Repairing hooks for repository '#{GitHosting.repository_name(repo)}' (in gitolite repository at '#{GitHosting.repository_path(repo)}')"
        else
          logger.info "[GitHosting] Setting up hooks for repository '#{GitHosting.repository_name(repo)}' (in gitolite repository at '#{GitHosting.repository_path(repo)}')"
        end

        begin
          repo_path = GitHosting.repository_path(repo)
          GitHosting.shell %[#{GitHosting.git_exec} --git-dir='#{repo_path}' config hooks.redmine_gitolite.key "#{hook_key}"]
          GitHosting.shell %[#{GitHosting.git_exec} --git-dir='#{repo_path}' config hooks.redmine_gitolite.projectid "#{repo.project.identifier}"]
          if GitHosting.multi_repos?
            GitHosting.shell %[#{GitHosting.git_exec} --git-dir='#{repo_path}' config hooks.redmine_gitolite.repositoryid "#{repo.identifier||''}"]
          end
          logger.info "[GitHosting] Done !"
          logger.info ""
        rescue
          logger.error "[GitHosting] setup_hooks_for_repository(#{repo.git_label}) failed!"
          logger.info ""
        end

      end

    end

  end

end
