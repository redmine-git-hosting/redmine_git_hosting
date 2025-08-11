module Orgmode

  # Represents a headline in an orgmode file.
  class Headline < Line

    # This is the "level" of the headline
    attr_reader :level

    # This is the headline text -- the part of the headline minus the leading
    # asterisks, the keywords, and the tags.
    attr_reader :headline_text

    # This contains the lines that "belong" to the headline.
    attr_reader :body_lines

    # These are the headline tags
    attr_reader :tags

    # Optional keyword found at the beginning of the headline.
    attr_reader :keyword

    # Valid states for partial export.
    # exclude::       The entire subtree from this heading should be excluded.
    # headline_only:: The headline should be exported, but not the body.
    # all::           Everything should be exported, headline/body/children.
    ValidExportStates = [:exclude, :headline_only, :all]

    # The export state of this headline. See +ValidExportStates+.
    attr_accessor :export_state

    # Include the property drawer items found for the headline
    attr_accessor :property_drawer

    # This is the regex that matches a line
    LineRegexp = /^\*+\s+/

    # This matches the tags on a headline
    TagsRegexp = /\s*:[\w:@]*:\s*$/

    # Special keywords allowed at the start of a line.
    Keywords = %w[TODO DONE]

    KeywordsRegexp = Regexp.new("^(#{Keywords.join('|')})\$")

    # This matches a headline marked as COMMENT
    CommentHeadlineRegexp = /^COMMENT\s+/

    def initialize(line, parser = nil, offset=0)
      super(line, parser)
      @body_lines = []
      @tags = []
      @export_state = :exclude
      @property_drawer = { }
      if (@line =~ LineRegexp) then
        @level = $&.strip.length + offset
        @headline_text = $'.strip
        if (@headline_text =~ TagsRegexp) then
          @tags = $&.split(/:/)              # split tag text on semicolon
          @tags.delete_at(0)                 # the first item will be empty; discard
          @headline_text.gsub!(TagsRegexp, "") # Removes the tags from the headline
        end
        @keyword = nil
        parse_keywords
      else
        raise "'#{line}' is not a valid headline"
      end
    end

    # Override Line.output_text. For a heading, @headline_text
    # is what we should output.
    def output_text
      return @headline_text
    end

    # Determines if a line is an orgmode "headline":
    # A headline begins with one or more asterisks.
    def self.headline?(line)
      line =~ LineRegexp
    end

    # Determines if a headline has the COMMENT keyword.
    def comment_headline?
      @headline_text =~ CommentHeadlineRegexp
    end

    # Overrides Line.paragraph_type.
    def paragraph_type
      :"heading#{@level}"
    end

    ######################################################################
    private

    def parse_keywords
      re = @parser.custom_keyword_regexp if @parser
      re ||= KeywordsRegexp
      words = @headline_text.split
      if words.length > 0 && words[0] =~ re then
        @keyword = words[0]
        @headline_text.sub!(Regexp.new("^#{@keyword}\s*"), "")
      end
    end
  end                           # class Headline
end                             # class Orgmode
