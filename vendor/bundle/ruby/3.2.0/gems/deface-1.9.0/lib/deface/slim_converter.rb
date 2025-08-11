require 'slim/erb_converter'

module Deface
  class SlimConverter

    def initialize(template, options = {})
      @template = template
    end

    def result
      conv = defined?(Slim::RailsTemplate) ? rails_converter : generic_converter
      conv.call(@template).gsub(/<%\s*%>/, '')
    end

    private

    def rails_converter
      slim_erb_converter.new(
        Temple::OptionMap.new(Slim::RailsTemplate.options.to_h.except(:engine))
      )
    end

    def generic_converter
      slim_erb_converter.new
    end

    def slim_erb_converter
      ::Slim::ERBConverter
    end
  end
end
