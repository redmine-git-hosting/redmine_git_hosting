class RepositoryPresenter < SimpleDelegator

  attr_reader :repository

  def initialize(repository, template)
    super(template)
    @repository = repository
  end


  def link_to_repository
    link_to repository.name, { controller: 'repositories', action: 'show', id: repository.project, repository_id: repository.identifier_param, rev: nil, path: nil }
  end


  def git_urls_box
    content_tag(:div, class: 'git_url_box', id: urls_container_id) do
      render_git_urls +
      render_git_url_text +
      render_permissions +
      render_clipboard_button
    end
  end


  private


    def render_git_urls
      content_tag(:ul, render_url_list, class: 'git_url_list')
    end


    def render_url_list
      s = ''
      repository.available_urls.each do |key, value|
        s << content_tag(:li, link_to(key.upcase, 'javascript:void(0)').html_safe, options_for_git_url(key, value))
      end
      s.html_safe
    end


    def options_for_git_url(key, value)
      { class: 'git_url', data: { url: value[:url], committer: value[:committer], target: element_name, committer: committer_label(value) } }
    end


    def render_git_url_text
      content_tag(:input, '', class: 'git_url_text', id: url_text_container_id, readonly: 'readonly')
    end


    def render_permissions
      content_tag(:div, content_tag(:span, '', id: permissions_container_id), class: 'git_url_permissions')
    end


    def render_clipboard_button
      content_tag(:div, image_tag('paste.png', plugin: 'redmine_bootstrap_kit'), class: 'clipboard_button', id: clipboard_container_id, data: clipboard_options)
    end


    def committer_label(value)
      value[:committer] == 'true' ? l(:label_read_write_permission) : l(:label_read_only_permission)
    end


    def element_name
      "repository_#{repository.id}"
    end


    def urls_container_id
      "git_url_box_#{element_name}"
    end


    def permissions_container_id
      "git_url_permissions_#{element_name}"
    end


    def url_text_container_id
      "git_url_text_#{element_name}"
    end


    def clipboard_container_id
      "clipboard_button_#{element_name}"
    end


    def clipboard_options
      { 'clipboard-target' => url_text_container_id }
    end

end
