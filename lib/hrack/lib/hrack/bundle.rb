require 'rack/builder'
require 'rack/parser'
require 'hrack/server'

module Hrack
  module Bundle
    extend self

    def new(config)
      Rack::Builder.new do
        use Rack::Parser
        run Hrack::Server.new(config)
      end
    end

  end
end
