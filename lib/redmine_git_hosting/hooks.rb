require 'github/markup'

module RedmineGitHosting
  class GitHostingHookListener < Redmine::Hook::ViewListener
    render_on :view_projects_show_left, partial: 'projects/git_urls'
    render_on :view_repository_edit_top, partial: 'repositories/edit_top'
    render_on :view_repositories_show_contextual, partial: 'repositories/show_top'
    render_on :view_repository_edit_bottom, partial: 'repositories/edit_bottom'
    render_on :view_repositories_show_sidebar, partial: 'repositories/git_hosting_sidebar'
    render_on :view_repositories_navigation, partial: 'repositories/git_hosting_navigation'

    def view_layouts_base_html_head(_context = {})
      header = ''
      header << stylesheet_link_tag(:plugin, plugin: 'redmine_git_hosting') + "\n"
      header << javascript_include_tag(:plugin, plugin: 'redmine_git_hosting') + "\n"
      header
    end

    def view_my_account_contextual(context)
      user = context[:user]
      link_to(l(:label_my_public_keys), public_keys_path, class: 'icon icon-passwd') if user.allowed_to_create_ssh_keys?
    end

    def self.default_url_options
      { script_name: Redmine::Utils.relative_url_root }
    end

    REDMINE_MARKDOWN_EXT = %w[.txt].freeze
    GITHUB_MARKDOWN_EXT  = %w[.markdown .mdown .mkdn .md].freeze

    def view_repositories_show_bottom(context)
      path        = get_path(context)
      rev         = get_rev(context)
      repository  = context[:repository]
      readme_file = find_readme_file(repository, path, rev)

      return '' if readme_file.nil?

      content = get_formated_text(repository, readme_file, rev)

      context[:controller].send(:render_to_string, partial: 'repositories/readme', locals: { html: content })
    end

    private

    def get_path(context)
      context[:request].params['path'] || ''
    end

    def get_rev(context)
      rev = context[:request].params['rev']
      rev.presence
    end

    def find_readme_file(repository, path, rev)
      (repository.entries(path, rev) || []).find { |f| f.name =~ /README((\.).*)?/i }
    end

    def get_formated_text(repository, file, rev)
      raw_readme_text = Redmine::CodesetUtil.to_utf8_by_setting(repository.cat(file.path, rev))
      content =
        if redmine_file?(file)
          formatter_name = Redmine::WikiFormatting.format_names.find { |name| name =~ /markdown/i }
          Redmine::WikiFormatting.formatter_for(formatter_name).new(raw_readme_text).to_html
        elsif github_file?(file)
          RedmineGitHosting::MarkdownRenderer.to_html(raw_readme_text)
        else
          GitHub::Markup.render(file.path, raw_readme_text)
        end
      content
    end

    def redmine_file?(file)
      REDMINE_MARKDOWN_EXT.include?(File.extname(file.path))
    end

    def github_file?(file)
      GITHUB_MARKDOWN_EXT.include?(File.extname(file.path))
    end
  end
end
