require_dependency 'user'

module RedmineGitHosting
  module Patches
    module UserPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          attr_accessor :status_has_changed

          has_many :gitolite_public_keys, :dependent => :destroy

          before_destroy :delete_ssh_keys, prepend: true

          after_save :check_if_status_changed

          after_commit ->(obj) { obj.update_repositories }, on: :update
        end
      end


      module InstanceMethods

        # Returns a unique identifier for this user to use for gitolite keys.
        # As login names may change (i.e., user renamed), we use the user id
        # with its login name as a prefix for readibility.
        def gitolite_identifier
          [RedmineGitolite::Config.get_setting(:gitolite_identifier_prefix), self.login.underscore.gsub(/[^0-9a-zA-Z]/, '_'), '_', self.id].join
        end


        protected


          def update_repositories
            if status_has_changed
              git_projects = self.projects.uniq.select{|p| p.gitolite_repos.any?}.map{|project| project.id}

              RedmineGitolite::GitHosting.logger.info { "User status has changed, update projects" }
              RedmineGitolite::GitHosting.resync_gitolite(:update_projects, git_projects)
            end
          end


        private


          def delete_ssh_keys
            RedmineGitolite::GitHosting.logger.info { "User '#{self.login}' has been deleted from Redmine delete membership and SSH keys !" }
          end


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
