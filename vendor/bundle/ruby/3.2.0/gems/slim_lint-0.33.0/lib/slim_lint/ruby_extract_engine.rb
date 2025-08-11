# frozen_string_literal: true

module SlimLint
  # Generates a {SlimLint::Sexp} suitable for consumption by the
  # {RubyExtractor}.
  #
  # This is mostly copied from Slim::Engine, with some filters and generators
  # omitted.
  class RubyExtractEngine < Temple::Engine
    filter :Encoding
    filter :RemoveBOM

    # Parse into S-expression using Slim parser
    use Slim::Parser

    # Perform additional processing so extracting Ruby code in {RubyExtractor}
    # is easier. We don't do this for regular linters because some information
    # about the original syntax tree is lost in the process, but that doesn't
    # matter in this case.
    use Slim::Embedded
    use Slim::Interpolation
    use SlimLint::Filters::SplatProcessor
    use Slim::DoInserter
    use Slim::EndInserter
    use SlimLint::Filters::ControlProcessor
    use SlimLint::Filters::AttributeProcessor
    filter :MultiFlattener
    filter :StaticMerger

    # Converts Array-based S-expressions into SlimLint::Sexp objects, and gives
    # them line numbers so we can easily map from the Ruby source to the
    # original source
    use SlimLint::Filters::SexpConverter
    use SlimLint::Filters::InjectLineNumbers
  end
end
