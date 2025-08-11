module Rack
  class Parser

    POST_BODY  = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH  = 'rack.request.form_hash'.freeze
    PARSER_RESULT  = 'rack.parser.result'.freeze

    JSON_PARSER   = proc { |data| JSON.parse data }
    ERROR_HANDLER = proc { |err, type| [400, {}, ['']] }

    attr_reader :parsers, :handlers, :logger

    def initialize(app, options = {})
      @app      = app
      @parsers  = options[:parsers]  || { %r{json} => JSON_PARSER }
      @handlers = options[:handlers] || {}
      @logger   = options[:logger]
    end

    def call(env)
      type   = Rack::Request.new(env).media_type
      parser = match_content_types_for(parsers, type) if type
      return @app.call(env) unless parser
      body = env[POST_BODY].read ; env[POST_BODY].rewind
      return @app.call(env) unless body && !body.empty?
      begin
        parsed = parser.last.call body
        env[PARSER_RESULT] = parsed
        env.update FORM_HASH => parsed, FORM_INPUT => env[POST_BODY] if parsed.is_a?(Hash)
      rescue StandardError => e
        warn! e, type
        handler   = match_content_types_for handlers, type
        handler ||= ['default', ERROR_HANDLER]
        return handler.last.call(e, type)
      end
      @app.call env
    end

    # Private: send a warning out to the logger
    #
    # error - Exception object
    # type  - String of the Content-Type
    #
    def warn!(error, type)
      return unless logger
      message = "[Rack::Parser] Error on %s : %s" % [type, error.to_s]
      logger.warn message
    end

    # Private: matches content types for the given media type
    #
    # content_types - An array of the parsers or handlers options
    # type          - The media type. gathered from the Rack::Request
    #
    # Returns The match from the parser/handler hash or nil
    def match_content_types_for(content_types, type)
      content_types.detect do |content_type, _|
        content_type.is_a?(Regexp) ? type.match(content_type) : type == content_type
      end
    end
  end
end
