require 'redmine/scm/adapters/git_adapter'

# Inherits from GitAdapter as it shares a lot of functionnalities.
# We can't override methods here (dont't know why) but we can in redmine_git_hosting/patches/gitolite_adapter_patch
# with alias_method_chain.
module Redmine
  module Scm
    module Adapters
      class XitoliteAdapter < GitAdapter
      end
    end
  end
end
