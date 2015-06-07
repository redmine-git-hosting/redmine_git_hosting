class ApplySettings
  unloadable

  attr_reader :old_valuehash
  attr_reader :valuehash

  attr_reader :resync_projects
  attr_reader :resync_ssh_keys
  attr_reader :flush_cache
  attr_reader :delete_trash_repo


  def initialize(old_valuehash, valuehash, opts = {})
    @old_valuehash     = old_valuehash
    @valuehash         = valuehash

    @resync_projects   = opts.delete(:resync_projects){ false }
    @resync_ssh_keys   = opts.delete(:resync_ssh_keys){ false }
    @flush_cache       = opts.delete(:flush_cache){ false }
    @delete_trash_repo = opts.delete(:delete_trash_repo){ [] }
  end


  def call
    apply_settings
  end


  private


    def apply_settings
      check_gitolite_location
      check_repo_hierarchy
      check_gitolite_config
      check_gitolite_default_values
      check_hook_config
      check_cache_config

      do_resync_projects
      do_resync_ssh_keys
      do_flush_cache
      do_delete_trash_repo
      do_enable_readme_creation
    end


    def value_has_changed?(params)
      old_valuehash[params] != valuehash[params]
    end


    def check_gitolite_location
      ## Gitolite location has changed. Remove temp directory, it will be recloned.
      if value_has_changed?(:gitolite_server_host) ||
         value_has_changed?(:gitolite_server_port) ||
         value_has_changed?(:gitolite_user)
        FileUtils.rm_rf RedmineGitHosting::Config.gitolite_temp_dir
      end
    end


    def check_repo_hierarchy
      ## Storage infos has changed, move repositories!
      if value_has_changed?(:gitolite_global_storage_dir)  ||
         value_has_changed?(:gitolite_redmine_storage_dir) ||
         value_has_changed?(:hierarchical_organisation)

        # Need to update everyone!
        # We take all root projects (even those who are closed) and move each hierarchy individually
        count = Project.includes(:repositories).all.select { |x| x if x.parent_id.nil? }.length
        GitoliteAccessor.move_repositories_tree(count) if count > 0
      end
    end


    def check_gitolite_config
      ## Gitolite config file has changed, create a new one!
      if value_has_changed?(:gitolite_config_file)       ||
         value_has_changed?(:gitolite_identifier_prefix) ||
         value_has_changed?(:gitolite_identifier_strip_user_id)
        options = { message: 'Gitolite configuration has been modified, resync all projects (active, closed, archived)...' }
        GitoliteAccessor.update_projects('all', options)
      end
    end


    def check_gitolite_default_values
      ## Gitolite default values has changed, update active projects
      if value_has_changed?(:gitolite_notify_global_prefix)         ||
         value_has_changed?(:gitolite_notify_global_sender_address) ||
         value_has_changed?(:gitolite_notify_global_include)        ||
         value_has_changed?(:gitolite_notify_global_exclude)

        # Need to update everyone!
        options = { message: 'Gitolite configuration has been modified, resync all active projects...' }
        GitoliteAccessor.update_projects('active', options)
      end
    end


    def check_hook_config
      ## Gitolite hooks config has changed, update our .gitconfig!
      if value_has_changed?(:gitolite_hooks_debug)        ||
         value_has_changed?(:gitolite_hooks_url)          ||
         value_has_changed?(:gitolite_hooks_are_asynchronous)

        # Need to update our .gitconfig
        RedmineGitHosting::Config.update_hook_params!
      end
    end


    def check_cache_config
      ## Gitolite cache has changed, clear cache entries!
      RedmineGitHosting::Cache.clear_obsolete_cache_entries if value_has_changed?(:gitolite_cache_max_time)
    end


    def do_resync_projects
      ## A resync has been asked within the interface, update all projects in force mode
      options = { message: 'Forced resync of all projects (active, closed, archived)...', force: true }
      GitoliteAccessor.update_projects('all', options) if resync_projects
    end


    def do_resync_ssh_keys
      ## A resync has been asked within the interface, update all projects in force mode
      GitoliteAccessor.resync_ssh_keys if resync_ssh_keys
    end


    def do_flush_cache
      ## A cache flush has been asked within the interface
      GitoliteAccessor.flush_git_cache if flush_cache
    end


    def do_delete_trash_repo
      GitoliteAccessor.purge_trash_bin(delete_trash_repo) if !delete_trash_repo.empty?
    end


    def do_enable_readme_creation
      valuehash[:init_repositories_on_create] == 'true' ? GitoliteAccessor.enable_readme_creation : GitoliteAccessor.disable_readme_creation
    end

end
