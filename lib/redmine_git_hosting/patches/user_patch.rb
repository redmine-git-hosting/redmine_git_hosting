require_dependency 'user'

module RedmineGitHosting
  module Patches
    module UserPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # Virtual attribute
          attr_accessor :status_has_changed

          # Relations
          has_many :gitolite_public_keys, dependent: :destroy

          # Callbacks
          after_save :check_if_status_changed
        end
      end


      module InstanceMethods

        # Returns a unique identifier for this user to use for gitolite keys.
        # As login names may change (i.e., user renamed), we use the user id
        # with its login name as a prefix for readibility.
        def gitolite_identifier
          [RedmineGitHosting::Config.gitolite_identifier_prefix, self.login.underscore.gsub(/[^0-9a-zA-Z]/, '_'), '_', self.id].join
        end


        def gitolite_projects
          projects.uniq.select{ |p| p.gitolite_repos.any? }
        end


        def status_has_changed?
          status_has_changed
        end


        private


          def check_if_status_changed
            if self.status_changed?
              self.status_has_changed = true
            else
              self.status_has_changed = false
            end
          end

      end

    end
  end
end

unless User.included_modules.include?(RedmineGitHosting::Patches::UserPatch)
  User.send(:include, RedmineGitHosting::Patches::UserPatch)
end
