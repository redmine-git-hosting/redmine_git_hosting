module Deface
  module Sources
    class Slim < Source
      def self.execute(override)
        if Rails.application.config.deface.slim_support
          Deface::SlimConverter.new(override.args[:slim]).result
        else
          raise Deface::NotSupportedError, "`#{override.name}` supplies :slim source, but slim_support is not detected."
        end
      end
    end
  end
end
