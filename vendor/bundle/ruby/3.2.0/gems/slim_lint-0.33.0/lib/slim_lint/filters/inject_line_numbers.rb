# frozen_string_literal: true

module SlimLint::Filters
  # Traverses a Temple S-expression (that has already been converted to
  # {SlimLint::Sexp} instances) and annotates them with line numbers.
  #
  # This is a hack that allows us to access line information directly from the
  # S-expressions, which makes a lot of other tasks easier.
  class InjectLineNumbers < Temple::Filter
    # {Sexp} representing a newline.
    NEWLINE_SEXP = SlimLint::Sexp.new([:newline])

    # Annotates the given {SlimLint::Sexp} with line number information.
    #
    # @param sexp [SlimLint::Sexp]
    # @return [SlimLint::Sexp]
    def call(sexp)
      @line_number = 1
      traverse(sexp)
      sexp
    end

    private

    # Traverses an {Sexp}, annotating it with line numbers.
    #
    # @param sexp [SlimLint::Sexp]
    def traverse(sexp)
      sexp.line = @line_number

      case sexp
      when SlimLint::Atom
        @line_number += sexp.strip.count("\n") if sexp.respond_to?(:count)
      when NEWLINE_SEXP
        @line_number += 1
      else
        sexp.each do |nested_sexp|
          traverse(nested_sexp)
        end
      end
    end
  end
end
