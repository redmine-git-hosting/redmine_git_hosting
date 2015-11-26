require 'github/markup'

module RedmineGitHosting
  module Hooks
    class DisplayRepositoryReadme < Redmine::Hook::ViewListener
      MARKDOWN_EXT = %w(.txt)

      def view_repositories_show_bottom(context)
        path        = get_path(context)
        rev         = get_rev(context)
        repo_id     = get_repo_id(context)
        repository  = find_repository(context, repo_id)
        readme_file = find_readme_file(repository, path, rev)

        return '' if readme_file.nil?

        formatter = get_formatter(repository, readme_file, rev)

        context[:controller].send(:render_to_string, {
          partial: 'repositories/readme',
          locals: { html: formatter }
        })
      end


      private


        def get_path(context)
          context[:request].params['path'] || ''
        end


        def get_rev(context)
          _rev = context[:request].params['rev']
          _rev.blank? ? nil : _rev
        end


        def get_repo_id(context)
          context[:request].params['repository_id']
        end


        def find_repository(context, repo_id)
          blk = repo_id ? ->(r) { r.identifier == repo_id } : ->(r) { r.is_default }
          context[:project].repositories.find(&blk)
        end


        def find_readme_file(repository, path, rev)
          (repository.entries(path, rev) || []).find { |f| f.name =~ /README((\.).*)?/i }
        end


        def get_formatter(repository, readme_file, rev)
          raw_readme_text = Redmine::CodesetUtil.to_utf8_by_setting(repository.cat(readme_file.path, rev))

          if MARKDOWN_EXT.include?(File.extname(readme_file.path))
            formatter_name = Redmine::WikiFormatting.format_names.find { |name| name =~ /markdown/i }
            formatter = Redmine::WikiFormatting.formatter_for(formatter_name).new(raw_readme_text).to_html
          else
            formatter = GitHub::Markup.render(readme_file.path, raw_readme_text)
          end

          formatter
        end

    end
  end
end
