require 'cgi'
require 'uri'

# :main: Creole

# The Creole parses and translates Creole formatted text into
# XHTML. Creole is a lightweight markup syntax similar to what many
# WikiWikiWebs use. Example syntax:
#
#   = Heading 1 =
#   == Heading 2 ==
#   === Heading 3 ===
#   **Bold text**
#   //Italic text//
#   [[Links]]
#   |=Table|=Heading|
#   |Table |Cells   |
#   {{image.png}}
#
# The simplest interface is Creole.creolize. The default handling of
# links allow explicit local links using the [[link]] syntax. External
# links will only be allowed if specified using http(s) and ftp(s)
# schemes. If special link handling is needed, such as inter-wiki or
# hierachical local links, you must inherit Creole::CreoleParser and
# override make_local_link.
#
# You can customize the created image markup by overriding
# make_image.

# Main Creole parser class.  Call CreoleParser#parse to parse Creole
# formatted text.
#
# This class is not reentrant. A separate instance is needed for
# each thread that needs to convert Creole to HTML.
#
# Inherit this to provide custom handling of links. The overrideable
# methods are: make_local_link
module Creole
  class Parser

    # Allowed url schemes
    # Examples: http https ftp ftps
    attr_accessor :allowed_schemes

    # Non-standard wiki text extensions enabled?
    # E.g. underlined, deleted text etc
    attr_writer :extensions
    def extensions?; @extensions; end

    # Disable url escaping for local links
    # Escaping: [[/Test]] --> %2FTest
    # No escaping: [[/Test]] --> Test
    attr_writer :no_escape
    def no_escape?; @no_escape; end

    # Create a new CreoleParser instance.
    def initialize(text, options = {})
      @allowed_schemes = %w(http https ftp ftps)
      @text            = text
      @extensions = @no_escape = nil
      options.each_pair {|k,v| send("#{k}=", v) }
    end

    # Convert CCreole text to HTML and return
    # the result. The resulting HTML does not contain <html> and
    # <body> tags.
    #
    # Example:
    #
    #    parser = CreoleParser.new("**Hello //World//**", :extensions => true)
    #    parser.to_html
    #       #=> "<p><strong>Hello <em>World</em></strong></p>"
    def to_html
      @out = ''
      @p = false
      @stack = []
      parse_block(@text)
      @out
    end

    protected

    # Escape any characters with special meaning in HTML using HTML
    # entities.
    def escape_html(string)
      CGI::escapeHTML(string)
    end

    # Escape any characters with special meaning in URLs using URL
    # encoding.
    def escape_url(string)
      CGI::escape(string)
    end

    def start_tag(tag)
      @stack.push(tag)
      @out << '<' << tag << '>'
    end

    def end_tag
      @out << '</' << @stack.pop << '>'
    end

    def toggle_tag(tag, match)
      if @stack.include?(tag)
        if @stack.last == tag
          end_tag
        else
          @out << escape_html(match)
        end
      else
        start_tag(tag)
      end
    end

    def end_paragraph
      end_tag while !@stack.empty?
      @p = false
    end

    def start_paragraph
      if @p
        @out << ' ' if @out[-1] != ?\s
      else
        end_paragraph
        start_tag('p')
        @p = true
      end
    end

    # Translate an explicit local link to a desired URL that is
    # properly URL-escaped. The default behaviour is to convert local
    # links directly, escaping any characters that have special
    # meaning in URLs. Relative URLs in local links are not handled.
    #
    # Examples:
    #
    #   make_local_link("LocalLink") #=> "LocalLink"
    #   make_local_link("/Foo/Bar") #=> "%2FFoo%2FBar"
    #
    # Must ensure that the result is properly URL-escaped. The caller
    # will handle HTML escaping as necessary. HTML links will not be
    # inserted if the function returns nil.
    #
    # Example custom behaviour:
    #
    #   make_local_link("LocalLink") #=> "/LocalLink"
    #   make_local_link("Wikipedia:Bread") #=> "http://en.wikipedia.org/wiki/Bread"
    def make_local_link(link) #:doc:
      no_escape? ? link : escape_url(link)
    end

    # Sanatize a direct url (e.g. http://wikipedia.org/). The default
    # behaviour returns the original link as-is.
    #
    # Must ensure that the result is properly URL-escaped. The caller
    # will handle HTML escaping as necessary. Links will not be
    # converted to HTML links if the function returns link.
    #
    # Custom versions of this function in inherited classes can
    # implement specific link handling behaviour, such as redirection
    # to intermediate pages (for example, for notifing the user that
    # he is leaving the site).
    def make_direct_link(url) #:doc:
      url
    end

    # Sanatize and prefix image URLs. When images are encountered in
    # Creole text, this function is called to obtain the actual URL of
    # the image. The default behaviour is to return the image link
    # as-is. No image tags are inserted if the function returns nil.
    #
    # Custom version of the method can be used to sanatize URLs
    # (e.g. remove query-parts), inhibit off-site images, or add a
    # base URL, for example:
    #
    #    def make_image_link(url)
    #       URI.join("http://mywiki.org/images/", url)
    #    end
    def make_image_link(url) #:doc:
      url
    end

    # Create image markup.  This
    # method can be overridden to generate custom
    # markup, for example to add html additional attributes or
    # to put divs around the imgs.
    def make_image(uri, alt)
      if alt
        '<img src="' << escape_html(uri) << '" alt="' << escape_html(alt) << '"/>'
      else
        '<img src="' << escape_html(uri) << '"/>'
      end
    end

    def make_headline(level, text)
      "<h#{level}>" << escape_html(text) << "</h#{level}>"
    end

    def make_explicit_link(link)
      begin
        uri = URI.parse(link)
        return uri.to_s if uri.scheme && @allowed_schemes.include?(uri.scheme)
      rescue URI::InvalidURIError
      end
      make_local_link(link)
    end

    def parse_inline(str)
      until str.empty?
        case str
        when /\A(\~)?((https?|ftps?):\/\/\S+?)(?=([\,.?!:;"'\)]+)?(\s|$))/
          str = $'
          if $1
            @out << escape_html($2)
          else
            if uri = make_direct_link($2)
              @out << '<a href="' << escape_html(uri) << '">' << escape_html($2) << '</a>'
            else
              @out << escape_html($&)
            end
          end
        when /\A\[\[\s*([^|]*?)\s*(\|\s*(.*?))?\s*\]\]/m
          str = $'
          link, content = $1, $3
          if uri = make_explicit_link(link)
            @out << '<a href="' << escape_html(uri) << '">'
            if content
              until content.empty?
                content = parse_inline_tag(content)
              end
            else
              @out << escape_html(link)
            end
            @out << '</a>'
          else
            @out << escape_html($&)
          end
        else
          str = parse_inline_tag(str)
        end
      end
    end

    def parse_inline_tag(str)
      case str
      when /\A\{\{\{(.*?\}*)\}\}\}/
        @out << '<tt>' << escape_html($1) << '</tt>'
      when /\A\{\{\s*(.*?)\s*(\|\s*(.*?)\s*)?\}\}/
        if uri = make_image_link($1)
          @out << make_image(uri, $3)
        else
          @out << escape_html($&)
        end
      when /\A([:alpha:]|[:digit:])+/
        @out << $&
      when /\A\s+/
        @out << ' ' if @out[-1] != ?\s
      when /\A\*\*/
        toggle_tag 'strong', $&
      when /\A\/\//
        toggle_tag 'em', $&
      when /\A\\\\/
        @out << '<br/>'
      else
        if @extensions
          case str
          when /\A__/
            toggle_tag 'u', $&
          when /\A\-\-/
            toggle_tag 'del', $&
          when /\A\+\+/
            toggle_tag 'ins', $&
          when /\A\^\^/
            toggle_tag 'sup', $&
          when /\A\~\~/
            toggle_tag 'sub', $&
          when /\A\(R\)/i
            @out << '&#174;'
          when /\A\(C\)/i
            @out << '&#169;'
          when /\A~([^\s])/
            @out << escape_html($1)
          when /./
            @out << escape_html($&)
          end
        else
          case str
          when /\A~([^\s])/
            @out << escape_html($1)
          when /./
            @out << escape_html($&)
          end
        end
      end
      return $'
    end

    def parse_table_row(str)
      @out << '<tr>'
      str.scan(/\s*\|(=)?\s*((\[\[.*?\]\]|\{\{.*?\}\}|[^|~]|~.)*)(?=\||$)/) do
        if !$2.empty? || !$'.empty?
          @out << ($1 ? '<th>' : '<td>')
          parse_inline($2) if $2
          end_tag while @stack.last != 'table'
          @out << ($1 ? '</th>' : '</td>')
        end
      end
      @out << '</tr>'
    end

    def make_nowikiblock(input)
      input.gsub(/^ (?=\}\}\})/, '')
    end

    def ulol?(x); x == 'ul' || x == 'ol'; end

    def parse_block(str)
      until str.empty?
        case str
        when /\A\{\{\{\r?\n(.*?)\r?\n\}\}\}/m
          end_paragraph
          nowikiblock = make_nowikiblock($1)
          @out << '<pre>' << escape_html(nowikiblock) << '</pre>'
        when /\A\s*-{4,}\s*$/
          end_paragraph
          @out << '<hr/>'
        when /\A\s*(={1,6})\s*(.*?)\s*=*\s*$(\r?\n)?/
          end_paragraph
          level = $1.size
          @out << make_headline(level, $2)
        when /\A[ \t]*\|.*$(\r?\n)?/
          if !@stack.include?('table')
            end_paragraph
            start_tag('table')
          end
          parse_table_row($&)
        when /\A\s*$(\r?\n)?/
          end_paragraph
        when /\A(\s*([*#]+)\s*(.*?))$(\r?\n)?/
          line, bullet, item = $1, $2, $3
          tag = (bullet[0,1] == '*' ? 'ul' : 'ol')
          if bullet[0,1] == '#' || bullet.size != 2 || @stack.find {|x| ulol?(x) }
            count = @stack.select { |x| ulol?(x) }.size

            while !@stack.empty? && count > bullet.size
              count -= 1 if ulol?(@stack.last)
              end_tag
            end

            end_tag while !@stack.empty? && @stack.last != 'li'

            if @stack.last == 'li' && count == bullet.size
              end_tag
              if @stack.last != tag
                end_tag
                count -= 1
              end
            end

            while count < bullet.size
              start_tag tag
              count += 1
              start_tag 'li' if count < bullet.size
            end

            @p = true
            start_tag('li')
            parse_inline(item)
          else
            start_paragraph
            parse_inline(line)
          end
        when /\A([ \t]*\S+.*?)$(\r?\n)?/
          start_paragraph
          parse_inline($1)
        else
          raise "Parse error at #{str[0,30].inspect}"
        end
        #p [$&, $']
        str = $'
      end
      end_paragraph
      @out
    end
  end
end
