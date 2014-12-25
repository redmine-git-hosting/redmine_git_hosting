module Hooks
  module BranchParser
    unloadable

    # Parse a reference component.  Three possibilities:
    #
    # 1) refs/type/name
    # 2) name
    #
    # here, name can have many components.
    @@refcomp = "[\\.\\-\\w_\\*]+"
    def refcomp_parse(spec)
      if (refcomp_parse = spec.match(/^(refs\/)?((#{@@refcomp})\/)?(#{@@refcomp}(\/#{@@refcomp})*)$/))
        if refcomp_parse[1]
          # Should be first class.  If no type component, return fail
          if refcomp_parse[3]
            {type: refcomp_parse[3], name: refcomp_parse[4]}
          else
            nil
          end
        elsif refcomp_parse[3]
          {type: nil, name: (refcomp_parse[3] + "/" + refcomp_parse[4])}
        else
          {type: nil, name: refcomp_parse[4]}
        end
      else
        nil
      end
    end

  end
end
