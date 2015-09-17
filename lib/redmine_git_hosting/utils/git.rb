module RedmineGitHosting
  module Utils
    module Git
      extend self

      REF_COMPONENT_PART  = '[\\.\\-\\w_\\*]+'
      REF_COMPONENT_REGEX = /\A(refs\/)?((#{REF_COMPONENT_PART})\/)?(#{REF_COMPONENT_PART}(\/#{REF_COMPONENT_PART})*)\z/

      # Parse a reference component. Two possibilities:
      #
      # 1) refs/type/name
      # 2) name
      #
      def parse_refspec(spec)
        parsed_refspec = spec.match(REF_COMPONENT_REGEX)
        return nil if parsed_refspec.nil?
        if parsed_refspec[1]
          # Should be first class.  If no type component, return fail
          if parsed_refspec[3]
            { type: parsed_refspec[3], name: parsed_refspec[4] }
          else
            nil
          end
        elsif parsed_refspec[3]
          { type: nil, name: "#{parsed_refspec[3]}/#{parsed_refspec[4]}" }
        else
          { type: nil, name: parsed_refspec[4] }
        end
      end


      def author_name(committer)
        committer.gsub(/\A([^<]+)\s+.*\z/, '\1')
      end


      def author_email(committer)
        committer.gsub(/\A.*<([^>]+)>.*\z/, '\1')
      end

    end
  end
end
