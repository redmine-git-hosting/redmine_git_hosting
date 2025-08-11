require_relative 'version'

class RubyPants < String
  extend RubyPantsVersion

  # Create a new RubyPants instance with the text in +string+.
  #
  # Allowed elements in the options array:
  #
  # 0  :: do nothing
  # 1  :: enable all, using only em-dash shortcuts
  # 2  :: enable all, using old school en- and em-dash shortcuts (*default*)
  # 3  :: enable all, using inverted old school en and em-dash shortcuts
  # -1 :: stupefy (translate HTML entities to their ASCII-counterparts)
  #
  # If you don't like any of these defaults, you can pass symbols to change
  # RubyPants' behavior:
  #
  # <tt>:quotes</tt>         :: quotes
  # <tt>:backticks</tt>      :: backtick quotes (``double'' only)
  # <tt>:allbackticks</tt>   :: backtick quotes (``double'' and `single')
  # <tt>:dashes</tt>         :: dashes
  # <tt>:oldschool</tt>      :: old school dashes
  # <tt>:inverted</tt>       :: inverted old school dashes
  # <tt>:ellipses</tt>       :: ellipses
  # <tt>:prevent_breaks</tt> :: use nbsp and word-joiner to avoid breaking
  #                             before dashes and ellipses
  # <tt>:named_entities</tt> :: used named entities instead of the default
  #                             decimal entities (see below)
  # <tt>:convertquotes</tt>  :: convert <tt>&quot;</tt> entities to
  #                             <tt>"</tt>
  # <tt>:stupefy</tt>        :: translate RubyPants HTML entities
  #                             to their ASCII counterparts.
  #
  # In addition, you can customize the HTML entities that will be injected by
  # passing in a hash for the final argument. The defaults for these entities
  # are as follows:
  #
  # <tt>:single_left_quote</tt>  :: <tt>&#8216;</tt>
  # <tt>:double_left_quote</tt>  :: <tt>&#8220;</tt>
  # <tt>:single_right_quote</tt> :: <tt>&#8217;</tt>
  # <tt>:double_right_quote</tt> :: <tt>&#8221;</tt>
  # <tt>:em_dash</tt>            :: <tt>&#8212;</tt>
  # <tt>:en_dash</tt>            :: <tt>&#8211;</tt>
  # <tt>:ellipsis</tt>           :: <tt>&#8230;</tt>
  # <tt>:non_breaking_space</tt> :: <tt>&nbsp;</tt>
  # <tt>:word_joiner</tt>        :: <tt>&#8288;</tt>
  #
  # If the <tt>:named_entities</tt> option is used, the default entities are
  # as follows:
  #
  # <tt>:single_left_quote</tt>  :: <tt>&lsquo;</tt>
  # <tt>:double_left_quote</tt>  :: <tt>&ldquo;</tt>
  # <tt>:single_right_quote</tt> :: <tt>&rsquo;</tt>
  # <tt>:double_right_quote</tt> :: <tt>&rdquo;</tt>
  # <tt>:em_dash</tt>            :: <tt>&mdash;</tt>
  # <tt>:en_dash</tt>            :: <tt>&ndash;</tt>
  # <tt>:ellipsis</tt>           :: <tt>&hellip;</tt>
  # <tt>:non_breaking_space</tt> :: <tt>&nbsp;</tt>
  # <tt>:word_joiner</tt>        :: <tt>&#8288;</tt>
  #
  # If the <tt>:character_entities</tt> option is used, RubyPants will
  # emit Unicode characters directly, rather than HTML entities. By default
  # this excludes the space characters (non-breaking space and
  # word-joiner). To additionally emit Unicode space characters, use the
  # <tt>:character_spaces</tt> option.
  #
  def initialize(string, options=[2], entities = {})
    super string

    @options = [*options]
    @entities = default_entities
    @entities.merge!(named_entities)     if @options.include?(:named_entities)
    @entities.merge!(character_entities) if @options.include?(:character_entities)
    @entities.merge!(character_spaces)   if @options.include?(:character_spaces)
    @entities.merge!(entities)

    @single_left_quote  = @entities[:single_left_quote]
    @single_right_quote = @entities[:single_right_quote]
    @double_left_quote  = @entities[:double_left_quote]
    @double_right_quote = @entities[:double_right_quote]
    @ellipsis           = @entities[:ellipsis]
    @em_dash            = @entities[:em_dash]
    @en_dash            = @entities[:en_dash]
  end

  SPECIAL_HTML_TAGS = %r!\A<(/?)(pre|code|kbd|script|style|math)[\s>]!
  NON_WHITESPACE_CHARS = /\S/

  # Apply SmartyPants transformations.
  def to_html
    do_quotes = do_backticks = do_dashes = do_ellipses = do_stupify = nil
    convert_quotes = prevent_breaks = nil

    if @options.include?(0)
      # Do nothing.
      return self
    elsif @options.include?(1)
      # Do everything, turn all options on.
      do_quotes = do_backticks = do_ellipses = true
      do_dashes = :normal
    elsif @options.include?(2)
      # Do everything, turn all options on, use old school dash shorthand.
      do_quotes = do_backticks = do_ellipses = true
      do_dashes = :oldschool
    elsif @options.include?(3)
      # Do everything, turn all options on, use inverted old school
      # dash shorthand.
      do_quotes = do_backticks = do_ellipses = true
      do_dashes = :inverted
    elsif @options.include?(-1)
      do_stupefy = true
    end

    # Explicit flags override numeric flag groups.
    do_quotes      = true       if @options.include?(:quotes)
    do_backticks   = true       if @options.include?(:backticks)
    do_backticks   = :both      if @options.include?(:allbackticks)
    do_dashes      = :normal    if @options.include?(:dashes)
    do_dashes      = :oldschool if @options.include?(:oldschool)
    do_dashes      = :inverted  if @options.include?(:inverted)
    prevent_breaks = true       if @options.include?(:prevent_breaks)
    do_ellipses    = true       if @options.include?(:ellipses)
    convert_quotes = true       if @options.include?(:convertquotes)
    do_stupefy     = true       if @options.include?(:stupefy)

    # Parse the HTML
    tokens = tokenize

    # Keep track of when we're inside <pre> or <code> tags.
    in_pre = nil

    # Here is the result stored in.
    result = ""

    # This is a cheat, used to get some context for one-character
    # tokens that consist of just a quote char. What we do is remember
    # the last character of the previous text token, to use as context
    # to curl single- character quote tokens correctly.
    prev_token_last_char = nil

    tokens.each do |token|
      if token.first == :tag
        result << token[1]
        if token[1].end_with? '/>'
          # ignore self-closing tags
        elsif token[1] =~ SPECIAL_HTML_TAGS
          if $1 == '' && ! in_pre
            in_pre = $2
          elsif $1 == '/' && $2 == in_pre
            in_pre = nil
          end
        end
      else
        t = token[1]

        # Remember last char of this token before processing.
        last_char = t[-1].chr

        unless in_pre
          t = process_escapes t

          t.gsub!('&quot;', '"') if convert_quotes

          if do_dashes
            t = educate_dashes t, prevent_breaks           if do_dashes == :normal
            t = educate_dashes_oldschool t, prevent_breaks if do_dashes == :oldschool
            t = educate_dashes_inverted t, prevent_breaks  if do_dashes == :inverted
          end

          t = educate_ellipses t, prevent_breaks if do_ellipses

          # Note: backticks need to be processed before quotes.
          if do_backticks
            t = educate_backticks t
            t = educate_single_backticks t if do_backticks == :both
          end

          if do_quotes
            if t == "'"
              # Special case: single-character ' token
              if prev_token_last_char =~ NON_WHITESPACE_CHARS
                t = @single_right_quote
              else
                t = @single_left_quote
              end
            elsif t == '"'
              # Special case: single-character " token
              if prev_token_last_char =~ NON_WHITESPACE_CHARS
                t = @double_right_quote
              else
                t = @double_left_quote
              end
            else
              # Normal case:
              t = educate_quotes t
            end
          end

          t = stupefy_entities t if do_stupefy
        end

        prev_token_last_char = last_char
        result << t
      end
    end

    # Done
    result
  end

  protected

  # Return the string, with after processing the following backslash
  # escape sequences. This is useful if you want to force a "dumb" quote
  # or other character to appear.
  #
  # Escaped are:
  #      \\    \"    \'    \.    \-    \`
  #
  def process_escapes(str)
    str.
      gsub('\\\\', '&#92;').
      gsub('\"',   '&#34;').
      gsub("\\\'", '&#39;').
      gsub('\.',   '&#46;').
      gsub('\-',   '&#45;').
      gsub('\`',   '&#96;')
  end

  def self.n_of(n, x)
    x = Regexp.escape(x)
    /(?<!#{x})   # not preceded by x
     #{x}{#{n}}  # n of x
     (?!#{x})    # not followed by x
    /x
  end

  DOUBLE_DASH = n_of(2, '-')
  TRIPLE_DASH = n_of(3, '-')
  TRIPLE_DOTS = n_of(3, '.')

  # Return +str+ replacing all +patt+ with +repl+. If +prevent_breaks+ is true,
  # then replace spaces preceding +patt+ with a non-breaking space, and if there
  # are no spaces, then insert a word-joiner.
  #
  def educate(str, patt, repl, prevent_breaks)
    patt = /(?<spaces>[[:space:]]*)#{patt}/
    str.gsub(patt) do
      spaces = if prevent_breaks && $~['spaces'].length > 0
                 entity(:non_breaking_space) # * $~['spaces'].length
               elsif prevent_breaks
                 entity(:word_joiner)
               else
                 $~['spaces']
               end
      spaces + repl
    end
  end

  # Return the string, with each instance of "<tt>--</tt>" translated to an
  # em-dash HTML entity.
  #
  def educate_dashes(str, prevent_breaks=false)
    educate(str, DOUBLE_DASH, @em_dash, prevent_breaks)
  end

  # Return the string, with each instance of "<tt>--</tt>" translated to an
  # en-dash HTML entity, and each "<tt>---</tt>" translated to an
  # em-dash HTML entity.
  #
  def educate_dashes_oldschool(str, prevent_breaks=false)
    str = educate(str, TRIPLE_DASH, @em_dash, prevent_breaks)
    educate(str, DOUBLE_DASH, @en_dash, prevent_breaks)
  end

  # Return the string, with each instance of "<tt>--</tt>" translated
  # to an em-dash HTML entity, and each "<tt>---</tt>" translated to
  # an en-dash HTML entity. Two reasons why: First, unlike the en- and
  # em-dash syntax supported by +educate_dashes_oldschool+, it's
  # compatible with existing entries written before SmartyPants 1.1,
  # back when "<tt>--</tt>" was only used for em-dashes.  Second,
  # em-dashes are more common than en-dashes, and so it sort of makes
  # sense that the shortcut should be shorter to type. (Thanks to
  # Aaron Swartz for the idea.)
  #
  def educate_dashes_inverted(str, prevent_breaks=false)
    str = educate(str, TRIPLE_DASH, @en_dash, prevent_breaks)
    educate(str, DOUBLE_DASH, @em_dash, prevent_breaks)
  end

  SPACED_ELLIPSIS_PATTERN = /(?<!\.|\.[ ])\.[ ]\.[ ]\.(?!\.|[ ]\.)/

  # Return the string, with each instance of "<tt>...</tt>" translated
  # to an ellipsis HTML entity. Also converts the case where there are
  # spaces between the dots.
  #
  def educate_ellipses(str, prevent_breaks=false)
    str = educate(str, TRIPLE_DOTS, @ellipsis, prevent_breaks)
    educate(str, SPACED_ELLIPSIS_PATTERN,
            @ellipsis, prevent_breaks)
  end

  # Return the string, with "<tt>``backticks''</tt>"-style single quotes
  # translated into HTML curly quote entities.
  #
  def educate_backticks(str)
    str.
      gsub("``", @double_left_quote).
      gsub("''", @double_right_quote)
  end

  # Return the string, with "<tt>`backticks'</tt>"-style single quotes
  # translated into HTML curly quote entities.
  #
  def educate_single_backticks(str)
    str.
      gsub("`", @single_left_quote).
      gsub("'", @single_right_quote)
  end

  PUNCT_CLASS = '[!"#\$\%\'()*+,\-.\/:;<=>?\@\[\\\\\]\^_`{|}~]'.freeze
  SNGL_QUOT_PUNCT_CASE = /^'(?=#{PUNCT_CLASS}\B)/
  DBLE_QUOT_PUNCT_CASE = /^"(?=#{PUNCT_CLASS}\B)/

  STARTS_MIXED_QUOTS_WITH_SNGL = /'"(?=\w)/
  STARTS_MIXED_QUOTS_WITH_DBLE = /"'(?=\w)/

  DECADE_ABBR_CASE = /'(?=\d\ds)/

  CLOSE_CLASS = '[^\ \t\r\n\\[\{\(\-]'.freeze
  CHAR_LEADS_SNGL_QUOTE = /(#{CLOSE_CLASS})'/
  WHITESPACE_TRAILS_SNGL_QUOTE = /'(\s|s\b|$)/
  CHAR_LEADS_DBLE_QUOTE = /(#{CLOSE_CLASS})"/
  WHITESPACE_TRAILS_DBLE_QUOTE = /"(\s|s\b|$)/

  # Return the string, with "educated" curly quote HTML entities.
  #
  def educate_quotes(str)
    str = str.dup

    # Special case if the very first character is a quote followed by
    # punctuation at a non-word-break. Close the quotes by brute
    # force:
    str.gsub!(SNGL_QUOT_PUNCT_CASE,
              @single_right_quote)
    str.gsub!(DBLE_QUOT_PUNCT_CASE,
              @double_right_quote)

    # Special case for double sets of quotes, e.g.:
    #   <p>He said, "'Quoted' words in a larger quote."</p>
    str.gsub!(STARTS_MIXED_QUOTS_WITH_DBLE,
              "#{@double_left_quote}#{@single_left_quote}")
    str.gsub!(STARTS_MIXED_QUOTS_WITH_SNGL,
              "#{@single_left_quote}#{@double_left_quote}")

    # Special case for decade abbreviations (the '80s):
    str.gsub!(DECADE_ABBR_CASE,
              @single_right_quote)

    dec_dashes = "#{@en_dash}|#{@em_dash}"
    quote_precedent = "[[:space:]]|&nbsp;|--|&[mn]dash;|#{dec_dashes}|&#x201[34];"

    # Get most opening single quotes:
    str.gsub!(/(#{quote_precedent})'(?=\w)/,
             '\1' + @single_left_quote)

    # Single closing quotes:
    str.gsub!(CHAR_LEADS_SNGL_QUOTE,
              '\1' + @single_right_quote)
    str.gsub!(WHITESPACE_TRAILS_SNGL_QUOTE,
              @single_right_quote + '\1')

    # Any remaining single quotes should be opening ones:
    str.gsub!("'",
              @single_left_quote)

    # Get most opening double quotes:
    str.gsub!(/(#{quote_precedent})"(?=\w)/,
             '\1' + @double_left_quote)

    # Double closing quotes:
    str.gsub!(CHAR_LEADS_DBLE_QUOTE,
              '\1' + @double_right_quote)
    str.gsub!(WHITESPACE_TRAILS_DBLE_QUOTE,
              @double_right_quote + '\1')

    # Any remaining quotes should be opening ones:
    str.gsub!('"',
              @double_left_quote)

    str
  end

  # Return the string, with each RubyPants HTML entity translated to
  # its ASCII counterpart.
  #
  # Note: This is not reversible (but exactly the same as in SmartyPants)
  #
  def stupefy_entities(str)
    new_str = str.dup

    {
      :en_dash            => '-',
      :em_dash            => '--',
      :single_left_quote  => "'",
      :single_right_quote => "'",
      :double_left_quote  => '"',
      :double_right_quote => '"',
      :ellipsis           => '...'
    }.each do |k,v|
      new_str.gsub!(entity(k).to_s, v)
    end

    new_str
  end

  TAG_SOUP = /([^<]*)(<!--.*?-->|<[^>]*>)/m

  # Return an array of the tokens comprising the string. Each token is
  # either a tag (possibly with nested, tags contained therein, such
  # as <tt><a href="<MTFoo>"></tt>, or a run of text between
  # tags. Each element of the array is a two-element array; the first
  # is either :tag or :text; the second is the actual value.
  #
  # Based on the <tt>_tokenize()</tt> subroutine from Brad Choate's
  # MTRegex plugin.  <http://www.bradchoate.com/past/mtregex.php>
  #
  # This is actually the easier variant using tag_soup, as used by
  # Chad Miller in the Python port of SmartyPants.
  #
  def tokenize
    tokens = []

    prev_end = 0

    scan(TAG_SOUP) do
      tokens << [:text, $1] if $1 != ""
      tokens << [:tag, $2]
      prev_end = $~.end(0)
    end

    if prev_end < size
      tokens << [:text, self[prev_end..-1]]
    end

    tokens
  end

  def default_entities
    {
      :single_left_quote  => "&#8216;",
      :double_left_quote  => "&#8220;",
      :single_right_quote => "&#8217;",
      :double_right_quote => "&#8221;",
      :em_dash            => "&#8212;",
      :en_dash            => "&#8211;",
      :ellipsis           => "&#8230;",
      :non_breaking_space => "&nbsp;",
      :word_joiner        => "&#8288;",
    }
  end

  def named_entities
    {
      :single_left_quote  => '&lsquo;',
      :double_left_quote  => "&ldquo;",
      :single_right_quote => "&rsquo;",
      :double_right_quote => "&rdquo;",
      :em_dash            => "&mdash;",
      :en_dash            => "&ndash;",
      :ellipsis           => "&hellip;",
      :non_breaking_space => "&nbsp;",
      # :word_joiner      => N/A,
    }
  end

  def character_entities
    {
      :single_left_quote  => "\u2018",
      :double_left_quote  => "\u201C",
      :single_right_quote => "\u2019",
      :double_right_quote => "\u201D",
      :em_dash            => "\u2014",
      :en_dash            => "\u2013",
      :ellipsis           => "\u2026",
    }
  end

  def character_spaces
    {
      :non_breaking_space => "\u00A0",
      :word_joiner        => "\u2060",
    }
  end

  def entity(key)
    @entities[key]
  end
end
