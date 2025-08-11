module Deface
  module Sources
    class Template < Source
      class << self
        include TemplateHelper
      end

      def self.execute(override)
        load_template_source(override.args[:template], false)
      end
    end
  end
end
