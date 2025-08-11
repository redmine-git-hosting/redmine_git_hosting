module Deface
  module Sources
    class Cut < Source
      def self.execute(override)
        cut = override.args[:cut]
        if cut.is_a? Hash
          range = Deface::Matchers::Range.new('Cut', cut[:start], cut[:end]).matches(override.parsed_document).first
          range.map &:remove

          Deface::Parser.undo_erb_markup! range.map(&:to_s).join

        else
          element = override.parsed_document.css(cut).first

          if element.nil?
            override.failure = "failed to match :cut selector '#{cut}'"
            nil
          else
            Deface::Parser.undo_erb_markup! element.remove.to_s.clone
          end
        end
      end
    end
  end
end
