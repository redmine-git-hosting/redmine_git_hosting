class GitHostingObserver < ActiveRecord::Observer
  unloadable

  observe :project, :user, :gitolite_public_key, :member, :role, :repository

  @@updating_active = true
  @@updating_active_stack = 0
  @@updating_active_flags = {}
  @@cached_project_updates = []

  def reload_this_observer
    observed_classes.each do |klass|
      klass.name.constantize.add_observer(self)
    end
  end

  def self.set_update_active(*is_active)
    if !is_active || !is_active.first
      @@updating_active_stack += 1
    else
      is_active.each do |item|
        case item
          when Symbol then @@updating_active_flags[item] = true
          when Hash then @@updating_active_flags.merge!(item)
          when Project then @@cached_project_updates |= [item]
        end
      end

      # If about to transition to zero and have something to run, do it
      if @@updating_active_stack == 1 && (@@cached_project_updates.length > 0 || !@@updating_active_flags.empty?)
        @@cached_project_updates = @@cached_project_updates.flatten.uniq.compact
        GitHosting.update_repositories(@@cached_project_updates, @@updating_active_flags)
        @@cached_project_updates = []
        @@updating_active_flags = {}
      end

      # Wait until after running update_repositories before releasing
      @@updating_active_stack -= 1
      if @@updating_active_stack < 0
        @@updating_active_stack = 0
      end
    end
    @@updating_active = (@@updating_active_stack == 0)
  end

  # Register args for updating and then do it without allowing recursive calls
  def self.bracketed_update_repositories(*args)
    set_update_active(false)
    set_update_active(*args)
  end

  def after_create(object)
    if not object.is_a?(Project)
      update_repositories(object)
    end
  end

  def before_save(object)
    if object.is_a?(Repository::Git)
      GitHosting.logger.debug "On GitHostingObserver.before_save for Repository::Git"
    end
  end

  def after_save(object)
    update_repositories(object)
  end

  def after_destroy(object)
    if object.is_a?(Repository::Git)
      update_repositories(object, :delete => true)
      GitHostingCache.clear_cache_for_repository(object)
    else
      update_repositories(object)
    end
  end

  protected

  def update_repositories(object, *flags)
    projects = []
    case object
      when Repository::Git then projects.push(object.project)
      when User then projects = object.projects unless is_login_save?(object)
      when GitolitePublicKey then projects = object.user.projects
      when Member then projects.push(object.project)
      when Role then projects = object.members.map(&:project).flatten.uniq.compact
    end

    if (projects.length > 0)
      if (@@updating_active)
        GitHosting.update_repositories(projects,*flags)
      else
        @@cached_project_updates.concat(projects)
        @@updating_active_flags.merge!(*flags) unless flags.empty?
      end
    end
  end

  # Test for the fingerprint of changes to the user model when the User actually logs in.
  def is_login_save?(user)
    user.changed? && user.changed.length == 2 && user.changed.include?("updated_on") && user.changed.include?("last_login_on")
  end

end
