require_dependency 'user'

module RedmineGitHosting
  module Patches
    module UserPatch

      def self.prepended(base)
        base.class_eval do
          # Virtual attribute
          attr_accessor :status_has_changed

          # Relations
          has_many :gitolite_public_keys, dependent: :destroy

          has_many :protected_branches_members, dependent: :destroy, foreign_key: :principal_id
          has_many :protected_branches, through: :protected_branches_members

          # Callbacks
          after_save :check_if_status_changed
        end
      end


      # Returns a unique identifier for this user to use for gitolite keys.
      # As login names may change (i.e., user renamed), we use the user id
      # with its login name as a prefix for readibility.
      def gitolite_identifier
        identifier = [RedmineGitHosting::Config.gitolite_identifier_prefix, stripped_login]
        identifier.concat(['_', id]) unless RedmineGitHosting::Config.gitolite_identifier_strip_user_id?
        identifier.join
      end


      def gitolite_projects
        projects.uniq.select { |p| p.gitolite_repos.any? }
      end


      # Syntaxic sugar
      def status_has_changed?
        status_has_changed
      end


      def allowed_to_manage_repository?(repository)
        !roles_for_project(repository.project).select { |role| role.allowed_to?(:manage_repository) }.empty?
      end


      def allowed_to_commit?(repository)
        allowed_to?(:commit_access, repository.project)
      end


      def allowed_to_clone?(repository)
        allowed_to?(:view_changesets, repository.project)
      end


      def allowed_to_create_ssh_keys?
        allowed_to?(:create_gitolite_ssh_key, nil, global: true)
      end


      def allowed_to_download?(repository)
        git_allowed_to?(:download_git_revision, repository)
      end


      def git_allowed_to?(permission, repository)
        if repository.project.active?
          allowed_to?(permission, repository.project)
        else
          allowed_to?(permission, nil, global: true)
        end
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


        def stripped_login
          login.underscore.gsub(/[^0-9a-zA-Z]/, '_')
        end

    end
  end
end

unless User.included_modules.include?(RedmineGitHosting::Patches::UserPatch)
  User.send(:prepend, RedmineGitHosting::Patches::UserPatch)
end
