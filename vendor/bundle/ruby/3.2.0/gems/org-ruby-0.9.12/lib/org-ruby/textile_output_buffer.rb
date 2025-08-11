require 'stringio'

module Orgmode

  class TextileOutputBuffer < OutputBuffer

    def initialize(output)
      super(output)
      @add_paragraph = true
      @support_definition_list = true # TODO this should be an option
      @footnotes = []
    end

    def push_mode(mode, indent)
      super(mode, indent)
      @output << "bc. " if mode_is_code? mode
      if mode == :center or mode == :quote
        @add_paragraph = false
        @output << "\n"
      end
    end

    def pop_mode(mode = nil)
      m = super(mode)
      @list_indent_stack.pop
      if m == :center or m == :quote
        @add_paragraph = true
        @output << "\n"
      end
      m
    end

    # Maps org markup to textile markup.
    TextileMap = {
      "*" => "*",
      "/" => "_",
      "_" => "_",
      "=" => "@",
      "~" => "@",
      "+" => "+"
    }

    # Handles inline formatting for textile.
    def inline_formatting(input)
      @re_help.rewrite_emphasis input do |marker, body|
        m = TextileMap[marker]
        "#{m}#{body}#{m}"
      end
      @re_help.rewrite_subp input do |type, text|
        if type == "_" then
          "~#{text}~"
        elsif type == "^" then
          "^#{text}^"
        end
      end
      @re_help.rewrite_links input do |link, defi|
        [link, defi].compact.each do |text|
          # We don't support search links right now. Get rid of it.
          text.sub!(/\A(file:[^\s]+)::[^\s]*?\Z/, "\\1")
          text.sub!(/\A(file:[^\s]+)\.org\Z/i, "\\1.textile")
          text.sub!(/\Afile:(?=[^\s]+\Z)/, "")
        end

        # We don't add a description for images in links, because its
        # empty value forces the image to be inlined.
        defi ||= link unless link =~ @re_help.org_image_file_regexp
        link = link.gsub(/ /, "%%20")

        if defi =~ @re_help.org_image_file_regexp
          defi = "!#{defi}(#{defi})!"
        elsif defi
          defi = "\"#{defi}\""
        end

        if defi
          "#{defi}:#{link}"
        else
          "!#{link}(#{link})!"
        end
      end
      @re_help.rewrite_footnote input do |name, definition|
        # textile only support numerical names, so we need to do some conversion
        # Try to find the footnote and use its index
        footnote = @footnotes.select {|f| f[:name] == name }.first
        if footnote
          # The latest definition overrides other ones
          footnote[:definition] = definition if definition and not footnote[:definition]
        else
          # There is no footnote with the current name so we add it
          footnote = { :name => name, :definition => definition }
          @footnotes << footnote
        end

        "[#{@footnotes.index(footnote)}]"
      end
      Orgmode.special_symbols_to_textile(input)
      input = @re_help.restore_code_snippets input
      input
    end

    def output_footnotes!
      return false if @footnotes.empty?

      @footnotes.each do |footnote|
        index = @footnotes.index(footnote)
        @output << "\nfn#{index}. #{footnote[:definition] || 'DEFINITION NOT FOUND' }\n"
      end

      return true
    end

    # Flushes the current buffer
    def flush!
      return false if @buffer.empty? and @output_type != :blank
      @logger.debug "FLUSH ==========> #{@output_type}"
      @buffer.gsub!(/\A\n*/, "")

      case
      when preserve_whitespace?
        @output << @buffer << "\n"

      when @output_type == :blank
        @output << "\n"

      else
        case current_mode
        when :paragraph
          @output << "p. " if @add_paragraph
          @output << "p=. " if @mode_stack[0] == :center
          @output << "bq. " if @mode_stack[0] == :quote

        when :list_item
          if @mode_stack[-2] == :ordered_list
            @output << "#" * @mode_stack.count(:list_item) << " "
          else # corresponds to unordered list
            @output << "*" * @mode_stack.count(:list_item) << " "
          end

        when :definition_term
          if @support_definition_list
            @output << "-" * @mode_stack.count(:definition_term) << " "
            @buffer.sub!("::", ":=")
          end
        end
        @output << inline_formatting(@buffer) << "\n"
      end
      @buffer = ""
    end

    def add_line_attributes headline
      @output << "h#{headline.level}. "
    end
  end                           # class TextileOutputBuffer
end                             # module Orgmode
