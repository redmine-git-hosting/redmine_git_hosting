module ExtendProjectsHelper

  def render_feature(repository, feature)
    css_class = [ 'icon icon-git' ]

    case feature
    when :deployment_credentials
      label = [ l(:label_deployment_credentials) ]
      css_class << 'icon-deployment-credentials'
      enabled = repository.deployment_credentials.active.any?

    when :post_receive_urls
      label = [ l(:label_post_receive_urls) ]
      css_class << 'icon-post-receive-urls'
      enabled = repository.post_receive_urls.active.any?

    when :mirrors
      label = [ l(:label_repository_mirrors) ]
      css_class << 'icon-mirrors'
      enabled = repository.mirrors.active.any?

    when :git_daemon
      label = [ l(:label_git_daemon) ]
      css_class << 'icon-git-daemon'
      enabled = (repository.project.is_public && repository.extra[:git_daemon])

    when :git_http
      label = [ l(:label_smart_http) ]
      css_class << 'icon-git-smarthttp'
      enabled = repository.extra[:git_http] != 0

    when :git_notify
      label = [ l(:label_git_notify) ]
      css_class << 'icon-git-notify'
      enabled = repository.extra[:git_notify]

    when :protected_branch
      label = [ l(:label_protected_branch) ]
      css_class << 'icon-git-protected-branch'
      enabled = repository.extra[:protected_branch]
    end

    label << "(#{l(:label_disabled)})" if !enabled
    css_class << 'icon-git-disabled' if !enabled

    content_tag(:span, '', :title => label.join(' '), :class => css_class.join(' '))
  end

end
