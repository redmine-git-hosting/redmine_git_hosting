# frozen_string_literal: true

module SlimLint
  # Temple engine used to generate a {Sexp} parse tree for use by linters.
  #
  # We omit a lot of the filters that are in {Slim::Engine} because they result
  # in information potentially being removed from the parse tree (since some
  # Sexp abstractions are optimized/removed or otherwise transformed). In order
  # for linters to be useful, they need to operate on the original parse tree.
  #
  # The other key task this engine accomplishes is converting the Array-based
  # S-expressions into {SlimLint::Sexp} objects, which have a number of helper
  # methods that makes working with them easier. It also annotates these
  # {SlimLint::Sexp} objects with line numbers so it's easy to cross reference
  # with the original source code.
  class Engine < Temple::Engine
    filter :Encoding
    filter :RemoveBOM

    # Parse into S-expression using Slim parser
    use Slim::Parser

    # Converts Array-based S-expressions into SlimLint::Sexp objects
    use SlimLint::Filters::SexpConverter

    # Annotates Sexps with line numbers
    use SlimLint::Filters::InjectLineNumbers

    # Parses the given source code into a Sexp.
    #
    # @param source [String] source code to parse
    # @return [SlimLint::Sexp] parsed Sexp
    def parse(source)
      call(source)
    rescue ::Slim::Parser::SyntaxError => e
      # Convert to our own exception type to isolate from upstream changes
      error = SlimLint::Exceptions::ParseError.new(e.error,
                                                   e.file,
                                                   e.line,
                                                   e.lineno,
                                                   e.column)
      raise error
    end
  end
end
