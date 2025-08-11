module Deface
  module Sources
    class Source
      class << self
        def to_sym
          self.to_s.demodulize.underscore.to_sym
        end
      end
    end
  end
end
