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
          [RedmineGitHosting::Config.gitolite_identifier_prefix, login.underscore.gsub(/[^0-9a-zA-Z]/, '_'), '_', id].join
        end


        def gitolite_projects
          projects.uniq.select{ |p| p.gitolite_repos.any? }
        end


        # Syntaxic sugar
        def status_has_changed?
          status_has_changed
        end


        def allowed_to_commit?(project)
          allowed_to?(:commit_access, project)
        end


        def allowed_to_ssh?
          !anonymous? && allowed_to?(:create_gitolite_ssh_key, nil, global: true)
        end


        private


          # This is Rails method : <attribute>_changed?
          # However, the value is cleared before passing the object to the controller.
          # We need to save it in virtual attribute to trigger Gitolite resync if changed.
          #
          def check_if_status_changed
            if status_changed?
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
