# frozen_string_literal: true

module SlimLint::Filters
  # A dumbed-down version of {Slim::Splat::Filter} which doesn't introduced
  # temporary variables or other cruft.
  class SplatProcessor < Slim::Filter
    # Handle slim splat expressions `[:slim, :splat, code]`
    #
    # @param code [String]
    # @return [Array]
    def on_slim_splat(code)
      [:code, code]
    end
  end
end
