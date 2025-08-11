# frozen_string_literal: true

module SlimLint
  # Holds the list of captures, providing a convenient interface for accessing
  # the values and unwrapping them on your behalf.
  class CaptureMap < Hash
    # Returns the captured value with the specified name.
    #
    # @param capture_name [Symbol]
    # @return [Object]
    def [](capture_name)
      if key?(capture_name)
        super.value
      else
        raise ArgumentError, "Capture #{capture_name.inspect} does not exist!"
      end
    end
  end
end
