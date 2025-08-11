module Deface
  module Sources
    class Copy < Source
      def self.execute(override)
        copy = override.args[:copy]
        if copy.is_a? Hash
          range = Deface::Matchers::Range.new('Copy', copy[:start], copy[:end]).matches(override.parsed_document).first
          Deface::Parser.undo_erb_markup! range.map(&:to_s).join
        else
          Deface::Parser.undo_erb_markup! override.parsed_document.css(copy).first.to_s.clone
        end
      end
    end
  end
end
