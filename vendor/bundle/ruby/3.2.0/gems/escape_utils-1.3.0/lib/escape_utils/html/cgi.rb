module EscapeUtils
  module CGIHtmlSafety
    def escapeHTML(html)
      ::EscapeUtils::HtmlSafety.escape_once(html) { |s| super(s) }
    end

    def unescapeHTML(html)
      super(html.to_s)
    end
  end
end

CGI.singleton_class.prepend(EscapeUtils::CGIHtmlSafety)
