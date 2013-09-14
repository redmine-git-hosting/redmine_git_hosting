module GitHostingHelper

  include Redmine::I18n

  def checked_image2(checked=true)
    if checked
      image_tag 'toggle_check.png'
    else
      image_tag 'exclamation.png'
    end
  end

  ## DEPLOYMENTS KEYS PERMISSIONS
  def self.can_create_deployment_keys_for_some_project(theuser = User.current)
    return true if theuser.admin?
    theuser.projects_by_role.each_key do |role|
      return true if role.allowed_to?(:create_deployment_keys)
    end
    false
  end

  def self.can_create_deployment_keys(project)
    return User.current.admin? || User.current.allowed_to?(:create_deployment_keys, project)
  end

  def self.can_view_deployment_keys(project)
    return User.current.admin? || User.current.allowed_to?(:view_deployment_keys, project)
  end

  def self.can_edit_deployment_keys(project)
    return User.current.admin? || User.current.allowed_to?(:edit_deployment_keys, project)
  end


  ## MIRRORS PERMISSIONS
  def self.can_create_mirrors(project)
    return User.current.allowed_to?(:create_repository_mirrors, project)
  end

  def self.can_view_mirrors(project)
    return User.current.allowed_to?(:view_repository_mirrors, project)
  end

  def self.can_edit_mirrors(project)
    return User.current.allowed_to?(:edit_repository_mirrors, project)
  end


  ## POST RECEIVE PERMISSIONS
  def self.can_create_post_receive_urls(project)
    return User.current.allowed_to?(:create_repository_post_receive_urls, project)
  end

  def self.can_view_post_receive_urls(project)
    return User.current.allowed_to?(:view_repository_post_receive_urls, project)
  end

  def self.can_edit_post_receive_urls(project)
    return User.current.allowed_to?(:edit_repository_post_receive_urls, project)
  end


  ## GIT MAILING LIST PERMISSIONS
  def self.can_create_git_notifications(project)
    return User.current.allowed_to?(:create_repository_git_notifications, project)
  end

  def self.can_view_git_notifications(project)
    return User.current.allowed_to?(:view_repository_git_notifications, project)
  end

  def self.can_edit_git_notifications(project)
    return User.current.allowed_to?(:edit_repository_git_notifications, project)
  end

  def self.mailing_list_default_users(repository)
    default_users = repository.project.member_principals.map(&:user).compact.uniq
    default_users = default_users.select{|user| user.allowed_to?(:receive_git_notifications, repository.project)}.map(&:mail)
    return default_users.uniq.sort
  end

  def self.mailing_list_effective(repository)
    mailing_list = {}

    # First collect all project users
    default_users = mailing_list_default_users(repository)
    if !default_users.empty?
      default_users.each do |mail|
        mailing_list[mail] = :project
      end
    end

    # Then add global include list
    if !GitHostingConf.gitolite_notify_global_include.empty?
      GitHostingConf.gitolite_notify_global_include.sort.each do |mail|
        mailing_list[mail] = :global
      end
    end

    # Then filter
    mailing_list = filter_list(mailing_list, repository)

    # Then add local include list
    if !repository.git_notification.nil? && !repository.git_notification.include_list.empty?
      repository.git_notification.include_list.sort.each do |mail|
        mailing_list[mail] = :local
      end
    end

    return mailing_list
  end

  def self.filter_list(mail_list, repository)
    mailing_list = {}
    exclude_list = []

    # Build exclusion list
    if !GitHostingConf.gitolite_notify_global_exclude.empty?
      exclude_list = exclude_list + GitHostingConf.gitolite_notify_global_exclude
    end

    if !repository.git_notification.nil? && !repository.git_notification.exclude_list.empty?
      exclude_list = exclude_list + repository.git_notification.exclude_list
    end

    exclude_list = exclude_list.uniq.sort

    mail_list.each do |mail, from|
      mailing_list[mail] = from unless exclude_list.include?(mail)
    end

    return mailing_list
  end

  ## GIT DAEMON ENABLED?
  def self.git_daemon_enabled(repository, value)
    gd = 1
    if repository && !repository.extra.nil?
      gd = repository.extra[:git_daemon] ? repository.extra[:git_daemon] : gd
    end
    gd = repository.project.is_public ? gd : 0
    return return_selected_string(gd, value)
  end


  ## SMART HTTP ENABLED?
  def self.git_http_enabled(repository, value)
    gh = 1
    if repository && !repository.extra.nil?
      gh = repository.extra[:git_http] ? repository.extra[:git_http] : gh
    end
    return return_selected_string(gh, value)
  end


  ## NOTIFY CIA ENABLED?
  def self.git_notify_cia(repository, value)
    nc = 0
    if repository && !repository.extra.nil?
      nc = repository.extra[:notify_cia] ? repository.extra[:notify_cia] : nc
    end
    return return_selected_string(nc, value)
  end


  # Port-receive Mode
  def self.post_receive_mode(prurl)
    if prurl.active == 0
      l(:label_mirror_inactive)
    elsif prurl.mode == :github
      l(:label_github_post)
    else
      l(:label_empty_get)
    end
  end


  # Refspec for mirrors
  def self.refspec(mirror, max_refspec=0)
    if mirror.push_mode == RepositoryMirror::PUSHMODE_MIRROR
      l(:all_references)
    else
      result = []
      result << l(:all_branches) if mirror.include_all_branches
      result << l(:all_tags) if mirror.include_all_tags
      result << mirror.explicit_refspec if (max_refspec == 0) || ((1..max_refspec) === mirror.explicit_refspec.length)
      result << l(:explicit) if (max_refspec > 0) && (mirror.explicit_refspec.length > max_refspec)
      result.join(",<br />")
    end
  end


  # Mirror Mode
  def self.mirror_mode(mirror)
    if mirror.active == 0
      l(:label_mirror_inactive)
    else
      [l(:label_mirror), l(:label_forced), l(:label_unforced)][mirror.push_mode]
    end
  end


  def self.return_selected_string(found_value, to_check_value)
    return "selected='selected'" if (found_value == to_check_value)
    return ""
  end


  def self.plugin_asset_link(asset_name)
    File.join(Redmine::Utils.relative_url_root, 'plugin_assets', 'redmine_git_hosting', 'images', asset_name)
  end


  def url_for_revision(revision)
    rev = revision.respond_to?(:identifier) ? revision.identifier : revision
    shorten_url(
      url_for(:controller => 'repositories', :action => 'revision', :id => revision.project,
        :rev => rev, :only_path => false, :host => Setting['host_name'], :protocol => Setting['protocol']
      )
    )
  end


  def url_for_revision_path(revision, path)
    rev = revision.respond_to?(:identifier) ? revision.identifier : revision
    shorten_url(
      url_for(:controller => 'repositories', :action => 'entry', :id => revision.project,
        :rev => rev, :path => path, :only_path => false, :host => Setting['host_name'],
        :protocol => Setting['protocol']
      )
    )
  end

  @@file_actions = {
    "a" => "add",
    "m" => "modify",
    "r" => "remove",
    "d" => "remove"
  }


  def map_file_action(action)
    @@file_actions.fetch(action.downcase, action)
  end

  @http_server = nil

  def shorten_url(url)
    if @http_server.nil?
      @uri = URI.parse("http://tinyurl.com/api-create.php")
      @http_server = Net::HTTP.new(@uri.host, @uri.port)
      @http_server.open_timeout = 1 # in seconds
      @http_server.read_timeout = 1 # in seconds
    end
    uri = @uri
    uri.query = "url=#{url}"
    request = Net::HTTP::Get.new(uri.request_uri)
    begin
      response = @http_server.request(request)
      GitHosting.logger.debug "Shortened URL is: #{response.body}"
      return response.body
    rescue Exception => e
      GitHosting.logger.warn "Failed to shorten url: #{e}"
      return url
    end
  end


  # Generic helper functions
  def reldir_add_dotslash(path)
    # Is this a relative path?
    stripped = (path || "").lstrip.rstrip
    norm = File.expand_path(stripped,"/")
    ((stripped[0,1] != "/")?".":"") + norm + ((norm[-1,1] != "/")?"/":"")
  end

end
