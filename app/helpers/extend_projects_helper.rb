module ExtendProjectsHelper

  def render_feature(repository, feature)
    method = "#{feature}_feature"
    label, css_class, enabled = self.send(method, repository)

    # Get css class
    base_class = [ 'icon icon-git' ]
    base_class << css_class
    base_class << 'icon-git-disabled' if !enabled

    # Get label
    base_label = []
    base_label << label
    base_label << "(#{l(:label_disabled)})" if !enabled

    content_tag(:span, '', title: base_label.join(' '), class: base_class.join(' '))
  end


  def deployment_credentials_feature(repository)
    label     = l(:label_deployment_credentials)
    css_class = 'icon-deployment-credentials'
    enabled   = repository.deployment_credentials.active.any?
    return label, css_class, enabled
  end


  def post_receive_urls_feature(repository)
    label     = l(:label_post_receive_urls)
    css_class = 'icon-post-receive-urls'
    enabled   = repository.post_receive_urls.active.any?
    return label, css_class, enabled
  end


  def mirrors_feature(repository)
    label     = l(:label_repository_mirrors)
    css_class = 'icon-mirrors'
    enabled   = repository.mirrors.active.any?
    return label, css_class, enabled
  end


  def git_daemon_feature(repository)
    label     = l(:label_git_daemon)
    css_class = 'icon-git-daemon'
    enabled   = (repository.project.is_public && repository.extra[:git_daemon])
    return label, css_class, enabled
  end


  def git_http_feature(repository)
    label     = l(:label_smart_http)
    css_class = 'icon-git-smarthttp'
    enabled   = repository.extra[:git_http] != 0
    return label, css_class, enabled
  end


  def git_notify_feature(repository)
    label     = l(:label_git_notify)
    css_class = 'icon-git-notify'
    enabled   = repository.extra[:git_notify]
    return label, css_class, enabled
  end


  def protected_branch_feature(repository)
    label     = l(:label_protected_branch)
    css_class = 'icon-git-protected-branch'
    enabled   = repository.extra[:protected_branch]
    return label, css_class, enabled
  end


  def git_annex_feature(repository)
    label     = l(:label_git_annex)
    css_class = 'icon-mirrors'
    enabled   = repository.extra[:git_annex]
    return label, css_class, enabled
  end

end
