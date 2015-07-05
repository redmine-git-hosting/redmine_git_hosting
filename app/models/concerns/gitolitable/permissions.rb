module Gitolitable
  module Permissions
    extend ActiveSupport::Concern

    def build_gitolite_permissions(old_perms = {})
      permissions_builder.build(self, gitolite_users, old_perms)
    end


    # We assume here that ':gitolite_config_file' is different than 'gitolite.conf'
    # like 'redmine.conf' with 'include "redmine.conf"' in 'gitolite.conf'.
    # This way, we know that all repos in this file are managed by Redmine so we
    # don't need to backup users
    #
    def backup_gitolite_permissions(current_permissions)
      if protected_branches_available? || RedmineGitHosting::Config.gitolite_identifier_prefix == ''
        {}
      else
        extract_permissions(current_permissions)
      end
    end


    private


      def permissions_builder
        if protected_branches_available?
          PermissionsBuilder::ProtectedBranches
        else
          PermissionsBuilder::Standard
        end
      end


      SKIP_USERS = ['gitweb', 'daemon', 'DUMMY_REDMINE_KEY', 'REDMINE_ARCHIVED_PROJECT', 'REDMINE_CLOSED_PROJECT']


      def extract_permissions(current_permissions)
        old_permissions = {}

        current_permissions.each do |perm, branch_settings|
          old_permissions[perm] = {}

          branch_settings.each do |branch, user_list|
            next if user_list.empty?

            new_user_list = []

            user_list.each do |user|
              # ignore these users
              next if SKIP_USERS.include?(user)

              # backup users that are not Redmine users
              new_user_list.push(user) if !user.include?(RedmineGitHosting::Config.gitolite_identifier_prefix)
            end

            old_permissions[perm][branch] = new_user_list if new_user_list.any?
          end
        end

        old_permissions
      end

  end
end
