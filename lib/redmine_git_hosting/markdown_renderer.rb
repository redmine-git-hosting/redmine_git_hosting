# frozen_string_literal: true

if RedmineGitHosting.old_redmine?
  require 'task_list/filter'
  require 'task_list/railtie'
end

require 'html/pipeline'

module RedmineGitHosting
  module MarkdownRenderer
    extend self

    def to_html(markdown)
      pipeline.call(markdown)[:output].to_s
    end

    private

    def pipeline
      HTML::Pipeline.new filters
    end

    if RedmineGitHosting.old_redmine?
      def filters
        [RedmineGitHosting::RedcarpetFilter,
         TaskList::Filter,
         HTML::Pipeline::AutolinkFilter,
         HTML::Pipeline::TableOfContentsFilter]
      end
    else
      def filters
        [RedmineGitHosting::RedcarpetFilter,
         HTML::Pipeline::AutolinkFilter,
         HTML::Pipeline::TableOfContentsFilter]
      end
    end
  end
end
