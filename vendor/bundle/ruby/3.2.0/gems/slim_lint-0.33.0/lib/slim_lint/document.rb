# frozen_string_literal: true

module SlimLint
  # Represents a parsed Slim document and its associated metadata.
  class Document
    # @return [SlimLint::Configuration] Configuration used to parse template
    attr_reader :config

    # @return [String] Slim template file path
    attr_reader :file

    # @return [SlimLint::Sexp] Sexpression representing the parsed document
    attr_reader :sexp

    # @return [String] original source code
    attr_reader :source

    # @return [Array<String>] original source code as an array of lines
    attr_reader :source_lines

    # Parses the specified Slim code into a {Document}.
    #
    # @param source [String] Slim code to parse
    # @param options [Hash]
    # @option options :file [String] file name of document that was parsed
    # @raise [Slim::Parser::Error] if there was a problem parsing the document
    def initialize(source, options)
      @config = options[:config]
      @file = options.fetch(:file, nil)

      process_source(source)
    end

    private

    # @param source [String] Slim code to parse
    # @raise [SlimLint::Exceptions::ParseError] if there was a problem parsing the document
    def process_source(source)
      @source = process_encoding(source)
      @source = strip_frontmatter(source)
      @source_lines = @source.split("\n")

      engine = SlimLint::Engine.new(file: @file)
      @sexp = engine.parse(@source)
    end

    # Ensure the string's encoding is valid.
    #
    # @param source [String]
    # @return [String] source encoded in a valid encoding
    def process_encoding(source)
      ::Temple::Filters::Encoding.new.call(source)
    end

    # Removes YAML frontmatter
    def strip_frontmatter(source)
      if config['skip_frontmatter'] &&
        source =~ /
          # From the start of the string
          \A
          # First-capture match --- followed by optional whitespace up
          # to a newline then 0 or more chars followed by an optional newline.
          # This matches the --- and the contents of the frontmatter
          (---\s*\n.*?\n?)
          # From the start of the line
          ^
          # Second capture match --- or ... followed by optional whitespace
          # and newline. This matches the closing --- for the frontmatter.
          (---|\.\.\.)\s*$\n?/mx
        source = ::Regexp.last_match.post_match
      end

      source
    end
  end
end
