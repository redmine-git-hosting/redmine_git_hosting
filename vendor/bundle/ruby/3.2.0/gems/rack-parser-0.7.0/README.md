# Rack::Parser #

Rack::Parser is a rack middleware that allows your application to do decode/parse incoming post data
into param hashes for your applications to use. You can provide a custom
Parser for things like JSON, XML, MSGPACK using your library of choice.

## Installation ##

install it via rubygems:

```
gem install rack-parser
```

or put it in your Gemfile:

```ruby
# Gemfile

gem 'rack-parser', :require => 'rack/parser'
```

## Usage ##

In a Sinatra or [Padrino](http://padrinorb.com) application, it would probably be something like:

```ruby
# app.rb

use Rack::Parser, :parsers => { 'application/json' => proc { |data| JSON.parse data },
                               'application/xml'  => proc { |data| XML.parse data },
                               %r{msgpack}        => proc { |data| Msgpack.parse data }
                             }
```

### Content Type Parsing ###

By default, Rack::Parser uses `JSON` decode/parse your JSON Data. This can be overwritten if you choose not to use
them. You can do it like so:

```ruby
use Rack::Parser, :parsers => {
  'application/json' => proc { |body| MyCustomJsonEngine.do_it body },
  'application/xml'  => proc { |body| MyCustomXmlEngine.decode body },
  'application/roll' => proc { |body| 'never gonna give you up'     }
}
```

### Error Handling ###

Rack::Parser comes with a default error handling response that is sent
if an error is to occur. If a `logger` is present, it will try to `warn`
with the content type and error message.

You can additionally customize the error handling response as well to
whatever it is you like:

```ruby
use Rack::Parser, :handlers => {
  'application/json' => proc { |e, type| [400, { 'Content-Type' => type }, ["broke"]] }
}
```

The error handler expects to pass both the `error` and `content_type` so
that you can use them within your responses. In addition, you can
override the default response as well.

If no content_type error handling response is present, it will return `400`

Do note, the error handler rescues exceptions that are descents of `StandardError`. See
http://www.mikeperham.com/2012/03/03/the-perils-of-rescue-exception/

### Regex Matching ###

With version `0.4.0`, you can specify regex matches for the content
types that you want the `parsers` and `handlers` to match.

NOTE: you need to explicitly pass a `Regexp` for it to regex match.

```ruby
parser  = proc { |data| JSON.parse data }
handler = proc { |e, type| [400, {}, 'boop'] }
use Rack::Parser, :parsers  => { %r{json}   => parser },
                  :handlers => { %r{heyyyy} => handler }
```

## Inspirations ##

This project came to being because of:

* [Niko Dittmann's](https://www.github.com/niko) [rack-post-body-to-params](https://www.github.com/niko/rack-post-body-to-params) which some of its ideas are instilled in this middleware.
* Rack::PostBodyContentTypeParser from rack-contrib which proved to be an inspiration for both libraries.


## External Sources/Documentations

* [Sinatra recipes](https://github.com/sinatra/sinatra-recipes/blob/master/middleware/rack_parser.md) - mini tutorial on using rack-parser (thanks to [Eric Gjertsen](https://github.com/ericgj))


## Contributors ##

* [Stephen Becker IV](https://github.com/sbeckeriv) - For initial custom error response handling work.
* [Tom May](https://github.com/tommay) - skip loading post body unless content type is set.
* [Moonsik Kang](https://github.com/deepblue) - skip rack parser for content types that are not explicitly set.
* [Guillermo Iguaran](https://github.com/guilleiguaran) - Updating `multi_xml` version dependency for XML/YAML exploit
* [Doug Orleans](https://github.com/dougo) - Handle only post-body parsing errors and let upstream errors propogate downstream
* [Akshay Moghe](https://github.com/amoghe) - Make default error handler rack compliant by responding to #each and use StandardError

## Copyright

Copyright © 2011,2012,2013 Arthur Chiu. See [MIT-LICENSE](https://github.com/achiu/rack-parser/blob/master/MIT-LICENSE) for details.

