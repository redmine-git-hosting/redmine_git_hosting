require 'rack/builder'
require 'hrack/server'

module Hrack
  module Bundle
    extend self

    def new(config)
      Rack::Builder.new do
        run Hrack::Server.new(config)
      end
    end

  end
end
