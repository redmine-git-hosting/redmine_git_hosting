module RedmineGitHosting
  module Patches
    module UserPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          has_many :gitolite_public_keys, :dependent => :destroy

          before_destroy :delete_ssh_keys, prepend: true
        end
      end


      module InstanceMethods

        def gitolite_identifier
          "#{RedmineGitolite::ConfigRedmine.get_setting(:gitolite_identifier_prefix)}#{self.login.underscore}".gsub(/[^0-9a-zA-Z\-]/, '_')
        end


        private


        def delete_ssh_keys
          RedmineGitolite::GitHosting.logger.info { "User '#{self.login}' has been deleted from Redmine delete membership and SSH keys !" }
        end

      end


    end
  end
end

unless User.included_modules.include?(RedmineGitHosting::Patches::UserPatch)
  User.send(:include, RedmineGitHosting::Patches::UserPatch)
end
