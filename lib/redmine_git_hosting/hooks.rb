# frozen_string_literal: true

require 'github/markup'

module RedmineGitHosting
  module Hooks
    class GitHostingHookListener < Redmine::Hook::ViewListener
      render_on :view_repository_edit_top, partial: 'repositories/edit_top'
      render_on :view_repositories_show_contextual, partial: 'repositories/show_top'
      render_on :view_repository_edit_bottom, partial: 'repositories/edit_bottom'
      render_on :view_repositories_show_sidebar, partial: 'repositories/git_hosting_sidebar'
      render_on :view_repositories_navigation, partial: 'repositories/git_hosting_navigation'
      render_on :view_layouts_base_html_head, partial: 'common/git_hosting_html_head'

      def view_my_account_contextual(context)
        user = context[:user]
        link_to(l(:label_my_public_keys), public_keys_path, class: 'icon icon-passwd') if user.allowed_to_create_ssh_keys?
      end

      def self.default_url_options
        { script_name: Redmine::Utils.relative_url_root }
      end

      def view_repositories_show_bottom(context)
        path        = get_path context
        rev         = get_rev context
        repository  = context[:repository]
        readme_file = find_readme_file repository, path, rev

        return '' if readme_file.nil?

        content = get_formatted_text repository, readme_file, rev

        context[:controller].send :render_to_string, partial: 'repositories/readme', locals: { html: content }
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

      def get_formatted_text(repository, file, rev)
        raw_readme_text = Redmine::CodesetUtil.to_utf8_by_setting repository.cat(file.path, rev)

        if redmine_file? file
          formatter_name = Redmine::WikiFormatting.format_names.find { |name| name =~ /markdown/i }
          Redmine::WikiFormatting.formatter_for(formatter_name).new(raw_readme_text).to_html
        elsif github_file? file
          RedmineGitHosting::MarkdownRenderer.to_html raw_readme_text
        else
          GitHub::Markup.render(file.path, raw_readme_text).gsub("\n", '<br/>')
        end
      end

      def redmine_file?(file)
        %w[.txt].include? File.extname(file.path)
      end

      def github_file?(file)
        %w[.markdown .mdown .mkdn .md].include? File.extname(file.path)
      end
    end
  end
end
