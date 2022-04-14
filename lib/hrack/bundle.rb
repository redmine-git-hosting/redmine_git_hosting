# frozen_string_literal: true

require 'rack/builder'
require 'rack/parser'

module Hrack
  module Bundle
    module_function

    def new(config)
      Rack::Builder.new do
        use Rack::Parser
        run Hrack::Server.new(config)
      end
    end
  end
end
