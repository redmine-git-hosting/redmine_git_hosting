# frozen_string_literal: true

module RedminePluginKit
  class Debug
    class << self
      def log(message = 'running')
        return if Rails.env.production?

        Rails.logger.debug { "#{Time.current.strftime '%H:%M:%S'} DEBUG [#{caller_locations(1..1).first.label}]: #{raw_msg message}" }
      end

      def msg(message = 'running')
        return if Rails.env.production?

        log message
        puts raw_msg(message) # rubocop: disable Rails/Output
        true
      end

      private

      def raw_msg(message)
        message.is_a?(String) ? message : message.inspect
      end
    end
  end
end
