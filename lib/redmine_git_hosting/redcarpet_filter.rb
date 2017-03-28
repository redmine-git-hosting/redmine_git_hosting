require 'html/pipeline/filter'
require 'html/pipeline/text_filter'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

module RedmineGitHosting
  class HTMLwithRouge < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  class RedcarpetFilter < HTML::Pipeline::TextFilter

    def initialize(text, context = nil, result = nil)
      super text, context, result
      @text = @text.delete "\r"
    end


    # Convert Markdown to HTML using the best available implementation
    # and convert into a DocumentFragment.
    #
    def call
      html = self.class.renderer.render(@text)
      html.rstrip!
      html
    end


    def self.renderer
      @renderer ||= begin
        Redcarpet::Markdown.new(HTMLwithRouge, markdown_options)
      end
    end


    def self.markdown_options
      @markdown_options ||= {
        fenced_code_blocks: true,
        lax_spacing:        true,
        strikethrough:      true,
        autolink:           true,
        tables:             true,
        underline:          true,
        highlight:          true
      }.freeze
    end

    private_class_method :markdown_options
  end
end
