# frozen_string_literal: true

module SlimLint::Filters
  # Converts a Temple S-expression comprised of {Array}s into {SlimLint::Sexp}s.
  #
  # These {SlimLint::Sexp}s include additional helpers that makes working with
  # them more pleasant.
  class SexpConverter < Temple::Filter
    # Converts the given {Array} to a {SlimLint::Sexp}.
    #
    # @param array_sexp [Array]
    # @return [SlimLint::Sexp]
    def call(array_sexp)
      SlimLint::Sexp.new(array_sexp)
    end
  end
end
