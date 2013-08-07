module RedmineGitHosting
  module Patches
    module UserPatch

      def self.included(base)
        base.class_eval do
          unloadable

          has_many :gitolite_public_keys, :dependent => :destroy
        end
      end

    end
  end
end

unless User.included_modules.include?(RedmineGitHosting::Patches::UserPatch)
  User.send(:include, RedmineGitHosting::Patches::UserPatch)
end
