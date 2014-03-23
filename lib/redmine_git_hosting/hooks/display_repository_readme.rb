require 'github/markup'

module RedmineGitHosting
  module Hooks
    class DisplayRepositoryReadme < Redmine::Hook::ViewListener
      unloadable

      @@markdown_ext = %w(.txt)

      def view_repositories_show_contextual(context)

        path = context[:request].params['path'] || ''
        rev = (_rev = context[:request].params['rev']).blank? ? nil : _rev
        repo_id = context[:request].params['repository_id']

        blk = repo_id ? lambda { |r| r.identifier == repo_id } : lambda { |r| r.is_default }
        repo = context[:project].repositories.find &blk

        unless file = (repo.entries(path, rev) || []).find { |entry| entry.name =~ /README((\.).*)?/i }
          return ''
        end

        raw_readme_text = repo.cat(file.path, rev)

        formatter_name = ''
        if @@markdown_ext.include?(File.extname(file.path))
          formatter_name = Redmine::WikiFormatting.format_names.find { |name| name =~ /markdown/i }
          formatter = Redmine::WikiFormatting.formatter_for(formatter_name).new(raw_readme_text).to_html
        else
          formatter = GitHub::Markup.render(file.path, raw_readme_text)
        end

        context[:controller].send(:render_to_string, {
          :partial => 'repositories/readme',
          :locals => {:html => formatter}
        })
      end

    end
  end
end
