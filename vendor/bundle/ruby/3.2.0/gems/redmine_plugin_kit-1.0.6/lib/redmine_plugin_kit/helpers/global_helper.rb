# frozen_string_literal: true

module RedminePluginKit
  module Helpers
    module GlobalHelper
      def link_to_external(name, link, **options)
        options[:class] ||= 'external'
        options[:class] = "#{options[:class]} external" if options[:class].exclude? 'external'
        options[:rel] ||= 'noopener noreferrer'

        link_to name, link, **options
      end

      def link_to_url(url, **options)
        return if url.blank?

        parts = url.split '://'
        name = if parts.count.positive?
                 parts.shift
                 parts.join.chomp '/'
               else
                 url.chomp '/'
               end

        link_to_external name, url, **options
      end
    end
  end
end
