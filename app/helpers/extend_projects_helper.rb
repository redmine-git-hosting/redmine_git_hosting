module ExtendProjectsHelper
  def render_feature(repository, feature)
    method = "#{feature}_feature"
    label, css_class, enabled = send(method, repository)

    # Get css class
    base_class = ['icon-git']
    base_class << css_class
    base_class << 'icon-git-disabled' unless enabled

    # Get label
    base_label = []
    base_label << label
    base_label << "(#{l(:label_disabled)})" unless enabled

    content_tag(:i, '', title: base_label.join(' '), class: base_class)
  end

  def deployment_credentials_feature(repository)
    label     = l(:label_deployment_credentials)
    css_class = 'fas fa-lock'
    enabled   = repository.deployment_credentials.active.any?
    [label, css_class, enabled]
  end

  def post_receive_urls_feature(repository)
    label     = l(:label_post_receive_urls)
    css_class = 'fas fa-external-link-alt'
    enabled   = repository.post_receive_urls.active.any?
    [label, css_class, enabled]
  end

  def mirrors_feature(repository)
    label     = l(:label_repository_mirrors)
    css_class = 'fas fa-cloud-upload-alt'
    enabled   = repository.mirrors.active.any?
    [label, css_class, enabled]
  end

  def git_daemon_feature(repository)
    label     = l(:label_git_daemon)
    css_class = 'fab fa-git'
    enabled   = repository.git_access_available?
    [label, css_class, enabled]
  end

  def git_http_feature(repository)
    label     = l(:label_smart_http)
    css_class = 'fas fa-cloud-download-alt'
    enabled   = repository.smart_http_enabled?
    [label, css_class, enabled]
  end

  def git_notify_feature(repository)
    label     = l(:label_git_notify)
    css_class = 'fas fa-bullhorn'
    enabled   = repository.git_notification_enabled?
    [label, css_class, enabled]
  end

  def protected_branch_feature(repository)
    label     = l(:label_protected_branch)
    css_class = 'fas fa-shield-alt'
    enabled   = repository.protected_branches_available?
    [label, css_class, enabled]
  end

  def git_annex_feature(repository)
    label     = l(:label_git_annex)
    css_class = 'fas fa-cloud-upload-alt'
    enabled   = repository.git_annex_enabled?
    [label, css_class, enabled]
  end

  def public_repo_feature(repository)
    label     = l(:label_public_repo)
    css_class = 'fas fa-users'
    enabled   = repository.public_repo?
    [label, css_class, enabled]
  end
end
