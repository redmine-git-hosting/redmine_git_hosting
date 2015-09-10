module RedmineGitHosting
  module Utils
    module Git
      extend self

      # Parse a reference component.  Three possibilities:
      #
      # 1) refs/type/name
      # 2) name
      #
      # here, name can have many components.

      REF_COMPONENT_PART = '[\\.\\-\\w_\\*]+'
      REF_COMPONENT_REGEX = /\A(refs\/)?((#{REF_COMPONENT_PART})\/)?(#{REF_COMPONENT_PART}(\/#{REF_COMPONENT_PART})*)\z/

      def refcomp_parse(spec)
        refcomp_parse = spec.match(REF_COMPONENT_REGEX)
        return nil if refcomp_parse.nil?
        if refcomp_parse[1]
          # Should be first class.  If no type component, return fail
          if refcomp_parse[3]
            { type: refcomp_parse[3], name: refcomp_parse[4] }
          else
            nil
          end
        elsif refcomp_parse[3]
          { type: nil, name: "#{refcomp_parse[3]}/#{refcomp_parse[4]}" }
        else
          { type: nil, name: refcomp_parse[4] }
        end
      end

    end
  end
end
