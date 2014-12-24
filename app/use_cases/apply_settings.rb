class ApplySettings
  unloadable

  attr_reader :old_valuehash
  attr_reader :valuehash

  attr_reader :resync_projects
  attr_reader :resync_ssh_keys
  attr_reader :flush_cache


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
      check_repo_hierarchy
      check_gitolite_config
      check_gitolite_default_values
      check_hook_install
      check_hook_config
      check_cache_config
      do_resync_projects
      do_resync_ssh_keys
      do_flush_cache
    end


    def check_repo_hierarchy
      ## Storage infos has changed, move repositories!
      if old_valuehash[:gitolite_global_storage_dir]  != valuehash[:gitolite_global_storage_dir]  ||
         old_valuehash[:gitolite_redmine_storage_dir] != valuehash[:gitolite_redmine_storage_dir] ||
         old_valuehash[:hierarchical_organisation]    != valuehash[:hierarchical_organisation]

        # Need to update everyone!
        # We take all root projects (even those who are closed) and move each hierarchy individually
        count = Project.includes(:repositories).all.select { |x| x if x.parent_id.nil? }.length
        if count > 0
          MoveRepositoriesTree.new(count).call
        end
      end
    end


    def check_gitolite_config
      ## Gitolite config file has changed, create a new one!
      if old_valuehash[:gitolite_config_file] != valuehash[:gitolite_config_file] ||
         old_valuehash[:gitolite_config_has_admin_key] != valuehash[:gitolite_config_has_admin_key]

        options = { message: "Gitolite configuration has been modified, resync all projects (active, closed, archived)..." }
        UpdateProjects.new('all', options).call
      end
    end


    def check_gitolite_default_values
      ## Gitolite default values has changed, update active projects
      if old_valuehash[:gitolite_notify_global_prefix]         != valuehash[:gitolite_notify_global_prefix]         ||
         old_valuehash[:gitolite_notify_global_sender_address] != valuehash[:gitolite_notify_global_sender_address] ||
         old_valuehash[:gitolite_notify_global_include]        != valuehash[:gitolite_notify_global_include]        ||
         old_valuehash[:gitolite_notify_global_exclude]        != valuehash[:gitolite_notify_global_exclude]

        options = { message: "Gitolite configuration has been modified, resync all active projects..." }
        UpdateProjects.new('active', options).call
      end
    end


    def check_hook_install
      ## Gitolite user has changed, check if this new one has our hooks!
      if old_valuehash[:gitolite_user] != valuehash[:gitolite_user]
        RedmineGitolite::HookManager.check_install!
      end
    end


    def check_hook_config
      ## Gitolite hooks config has changed, update our .gitconfig!
      if old_valuehash[:gitolite_hooks_debug]            != valuehash[:gitolite_hooks_debug]        ||
         old_valuehash[:gitolite_force_hooks_update]     != valuehash[:gitolite_force_hooks_update] ||
         old_valuehash[:gitolite_hooks_are_asynchronous] != valuehash[:gitolite_hooks_are_asynchronous]

        # Need to update our .gitconfig
        RedmineGitolite::HookManager.update_hook_params!
      end
    end


    def check_cache_config
      ## Gitolite cache has changed, clear cache entries!
      if old_valuehash[:gitolite_cache_max_time] != valuehash[:gitolite_cache_max_time]
        RedmineGitolite::Cache.clear_obsolete_cache_entries
      end
    end


    def do_resync_projects
      ## A resync has been asked within the interface, update all projects in force mode
      if resync_projects
        options = { message: "Forced resync of all projects (active, closed, archived)...", force: true }
        UpdateProjects.new('all', options).call
      end
    end


    def do_resync_ssh_keys
      ## A resync has been asked within the interface, update all projects in force mode
      if resync_ssh_keys
        ResyncSshKey.new().call
      end
    end


    def do_flush_cache
      ## A cache flush has been asked within the interface
      if flush_cache
        FlushGitCache.new().call
      end
    end


    def do_delete_trash_repo
      if !delete_trash_repo.empty?
        PurgeRecycleBin.new(delete_trash_repo).call
      end
    end

end
