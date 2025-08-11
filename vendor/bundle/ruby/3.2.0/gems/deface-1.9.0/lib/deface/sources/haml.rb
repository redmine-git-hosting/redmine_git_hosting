module Deface
  module Sources
    class Haml < Source
      def self.execute(override)
        if Rails.application.config.deface.haml_support
          haml_engine = Deface::HamlConverter.new(override.args[:haml])
          haml_engine.render
        else
          raise Deface::NotSupportedError, "`#{override.name}` supplies :haml source, but haml_support is not detected."
        end
      end
    end
  end
end
