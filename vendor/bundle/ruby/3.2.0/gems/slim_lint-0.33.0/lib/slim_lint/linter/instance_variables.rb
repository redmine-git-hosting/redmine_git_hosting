# frozen_string_literal: true

module SlimLint
  # Searches for instance variables in partial or other templates.
  class Linter::InstanceVariables < Linter
    include LinterRegistry

    on_start do |_sexp|
      processed_sexp = SlimLint::RubyExtractEngine.new.call(document.source)

      extractor = SlimLint::RubyExtractor.new
      extracted_source = extractor.extract(processed_sexp)
      next if extracted_source.source.empty?

      parsed_ruby = parse_ruby(extracted_source.source)
      next unless parsed_ruby

      report_instance_variables(parsed_ruby, extracted_source.source_map)
    end

    private

    def report_instance_variables(parsed_ruby, source_map)
      parsed_ruby.each_node do |node|
        next unless node.ivar_type?

        dummy_node = Struct.new(:line)
        report_lint(dummy_node.new(source_map[node.loc.line]),
                    'Avoid instance variables in the configured ' \
                    "view templates (found `#{node.source}`)")
      end
    end
  end
end
