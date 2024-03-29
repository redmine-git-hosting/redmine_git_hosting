# frozen_string_literal: true

module GitHostingHelper
  def present(object, klass = nil, *args)
    klass ||= "#{object.class.base_class}Presenter".constantize
    presenter = klass.new(object, self, *args)
    yield presenter if block_given?
    presenter
  end

  def checked_image_with_exclamation(checked:)
    checked ? image_tag('toggle_check.png') : image_tag('exclamation.png')
  end

  def render_shell_text(text)
    Redmine::SyntaxHighlighting.highlight_by_language text, 'shell'
  end

  def gitolite_project_settings_tabs
    tabs = []

    tabs << { name: 'db',
              action: :show,
              partial: 'projects/settings/db',
              label: :label_db }

    tabs << { name: 'db2',
              action: :show,
              partial: 'projects/settings/db',
              label: :label_db }
    tabs
  end
end
