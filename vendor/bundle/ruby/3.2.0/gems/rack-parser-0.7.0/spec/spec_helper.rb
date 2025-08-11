gem 'minitest'
require 'minitest/autorun'
require 'rack'
require 'rack/test'
require 'rack/builder'
require 'json'
require File.expand_path('../../lib/rack/parser', __FILE__)

class ParserApp
  def call(env)
    request = Rack::Request.new(env)
    type    = { 'Content-Type' => 'text/plain' }
    code, body =
      case request.path
      when '/'      then [200, 'Hello World']
      when '/post'  then [200, request.params.inspect]
      when '/error' then raise(StandardError, 'error!')
      else
        [404, 'Nothing']
      end
    [code, type, body]
  end
end

class Minitest::Spec
  include Rack::Test::Methods

  def app(*middleware)
    @builder = Rack::Builder.new
    @builder.use(*@stack)
    @builder.run ParserApp.new
    @builder.to_app
  end

  def stack(*middleware)
    @stack = middleware
  end
end
