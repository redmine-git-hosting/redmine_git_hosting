module Deface
  module Actions
    class Action
      def initialize(options = {})
      end

      class << self
        def to_sym
          self.to_s.demodulize.underscore.to_sym
        end
      end

      def range_compatible?
        false
      end

    end
  end
end
