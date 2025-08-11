require File.expand_path('../spec_helper', __FILE__)

describe Rack::Parser do

  it "allows you to setup parsers for content types" do
    middleware = Rack::Parser.new ParserApp, :parsers => { 'foo' => 'bar' }
    assert_equal 'bar', middleware.parsers['foo']
  end

  it "should not remove fields from options in setup" do
    options = {:parsers => { 'foo' => 'bar' }}
    middleware = Rack::Parser.new ParserApp, options
    refute_nil options[:parsers]
  end

  it "allows you to setup error handlers" do
    stack = Rack::Parser.new ParserApp, :handlers => { 'foo' => 'bar' }
    assert_equal 'bar', stack.handlers['foo']
  end

  it "parses a Content-Type" do
    payload = JSON.dump(:a => 1)
    parser = proc { |data| JSON.parse data }
    stack Rack::Parser, :parsers => { 'application/json' => parser }
    post '/post', payload, { 'CONTENT_TYPE' => 'application/json' }

    assert last_response.ok?
    assert_equal "{\"a\"=>1}", last_response.body
  end

  it "does nothing if unmatched Content-Type" do
    payload = JSON.dump(:a => 1)
    parser = proc { |data| JSON.parse data }
    stack Rack::Parser, :parsers => { 'application/json' => parser }
    post '/post', payload, { 'CONTENT_TYPE' => 'application/xml' }

    assert last_response.ok?
    assert_equal "{}", last_response.body # request.params won't pick up this content type
  end

  it "matches Content-Type by regex" do
    payload = JSON.dump(:a => 2)
    parser = proc { |data| JSON.parse data }
    stack Rack::Parser, :parsers => { %r{json} => parser }
    post '/post', payload, { 'CONTENT_TYPE' => 'application/vnd.foo+json' }

    assert last_response.ok?
    assert_equal "{\"a\"=>2}", last_response.body
  end

  it 'matches ambiguous string Content-Type and forces explicit regex' do
    payload = JSON.dump(:a => 2)
    parser = proc { |data| JSON.parse data }
    stack Rack::Parser, :parsers => { 'application/vnd.foo+json' => parser }
    post '/post', payload, { 'CONTENT_TYPE' => 'application/vnd.foo+json' }

    assert last_response.ok?
    assert_equal "{\"a\"=>2}", last_response.body
  end

  it "handles upstream errors" do
    assert_raises StandardError, 'error!' do
      parser = proc { |data| JSON.parse data }
      stack Rack::Parser, :parsers => { %r{json} => parser }
      post '/error', '{}', { 'CONTENT_TYPE' => 'application/json' }
    end
  end

  it "returns a default error" do
    parser  = proc { |data| raise StandardError, 'wah wah' }
    stack Rack::Parser, :parsers  => { %r{json} => parser }
    post '/post', '{}', { 'CONTENT_TYPE' => 'application/vnd.foo+json' }

    assert_equal 400, last_response.status
  end

  it "returns a custom error message" do
    parser  = proc { |data| raise StandardError, "wah wah" }
    handler = proc { |err, type| [500, {}, "%s : %s"  % [type, err]] }
    stack Rack::Parser, :parsers  => { %r{json} => parser },
                        :handlers => { %r{json} => handler }
    post '/post', '{}', { 'CONTENT_TYPE' => 'application/vnd.foo+json' }

    assert_equal 500, last_response.status
    assert_equal 'application/vnd.foo+json : wah wah', last_response.body
  end

  it 'returns a custome error for ambiguous string Content-Type and forces explicit regex' do
    parser  = proc { |data| raise StandardError, "wah wah" }
    handler = proc { |err, type| [500, {}, "%s : %s"  % [type, err]] }
    stack Rack::Parser, :parsers  => { %r{json} => parser },
                        :handlers => { 'application/vnd.foo+json' => handler }
    post '/post', '{}', { 'CONTENT_TYPE' => 'application/vnd.foo+json' }

    assert_equal 500, last_response.status
    assert_equal 'application/vnd.foo+json : wah wah', last_response.body
  end

  it "parses an array but do not set it to params" do
    payload = JSON.dump([1,2,3])
    parser = proc { |data| JSON.parse data }
    stack Rack::Parser, :parsers => { 'application/json' => parser }
    post '/post', payload, { 'CONTENT_TYPE' => 'application/json' }

    assert last_response.ok?
    assert_equal last_request.env['rack.parser.result'], [1, 2, 3]
    assert_equal last_request.env['rack.request.form_hash'], nil
  end
end
