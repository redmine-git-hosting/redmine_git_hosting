module Deface
  module Sources
    class Erb < Source
      def self.execute(override)
        override.args[:erb]
      end
    end
  end
end
