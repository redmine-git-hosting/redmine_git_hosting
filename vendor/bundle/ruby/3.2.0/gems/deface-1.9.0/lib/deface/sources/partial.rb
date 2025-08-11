module Deface
  module Sources
    class Partial < Source
      class << self
        include TemplateHelper
      end

      def self.execute(override)
        load_template_source(override.args[:partial], true)
      end
    end
  end
end
