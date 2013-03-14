module GitHosting
  module Patches
    module UserPatch

      def self.included(base)
        base.class_eval do
          unloadable
          # initialize association from user -> gitolite_public_keys
          has_many :gitolite_public_keys, :dependent => :destroy
        end
      end

    end
  end
end

# Patch in changes
User.send(:include, GitHosting::Patches::UserPatch)
