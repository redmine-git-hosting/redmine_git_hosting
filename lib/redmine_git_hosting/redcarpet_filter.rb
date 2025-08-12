# frozen_string_literal: true

require 'html/pipeline/filter'
require 'html/pipeline/text_filter'

module RedmineGitHosting
  class RedcarpetFilter < HTML::Pipeline::TextFilter
    def initialize(text, context = nil, result = nil)
      super text, context, result
      @text = @text.delete "\r"
    end

    # Convert Markdown to HTML using Redmine's WikiFormatting system
    # for consistency with Redmine's text formatting configuration.
    #
    def call
      html = markdown_formatter.new(@text).to_html
      html.rstrip!
      html
    end

    private

    def markdown_formatter
      # Find the markdown formatter from Redmine's WikiFormatting system
      formatter_name = Redmine::WikiFormatting.format_names.find { |name| name =~ /markdown/i }
      
      if formatter_name
        Redmine::WikiFormatting.formatter_for(formatter_name)
      else
        # Fallback to textile formatter if no markdown formatter is available
        Redmine::WikiFormatting.formatter_for('textile')
      end
    end
  end
end
