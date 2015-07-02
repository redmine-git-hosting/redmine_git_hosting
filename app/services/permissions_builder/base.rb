module PermissionsBuilder
  class Base

    SKIP_USERS = ['gitweb', 'daemon', 'DUMMY_REDMINE_KEY', 'REDMINE_ARCHIVED_PROJECT', 'REDMINE_CLOSED_PROJECT']

    attr_reader :repository
    attr_reader :gitolite_users
    attr_reader :old_permissions
    attr_reader :project


    def initialize(repository, gitolite_users, old_permissions = {})
      @repository      = repository
      @gitolite_users  = gitolite_users
      @old_permissions = old_permissions
      @project         = repository.project
    end


    class << self

      def build(repository, gitolite_users, old_permissions = {})
        new(repository, gitolite_users, old_permissions).build
      end


      def get_permissions(repo_conf)
        current_permissions = repo_conf.permissions[0]
        old_permissions = {}

        current_permissions.each do |perm, branch_settings|
          old_permissions[perm] = {}

          branch_settings.each do |branch, user_list|
            next if user_list.empty?

            new_user_list = []

            user_list.each do |user|
              ## We assume here that ':gitolite_config_file' is different than 'gitolite.conf'
              ## like 'redmine.conf' with 'include "redmine.conf"' in 'gitolite.conf'.
              ## This way, we know that all repos in this file are managed by Redmine so we
              ## don't need to backup users
              next if gitolite_identifier_prefix == ''

              # ignore these users
              next if SKIP_USERS.include?(user)

              # backup users that are not Redmine users
              new_user_list.push(user) if !user.include?(gitolite_identifier_prefix)
            end

            old_permissions[perm][branch] = new_user_list if new_user_list.any?
          end
        end

        old_permissions
      end


      def gitolite_identifier_prefix
        RedmineGitHosting::Config.gitolite_identifier_prefix
      end

    end


    def build
      raise NotImplementedError
    end


    private


      def has_no_users?(type)
        gitolite_users[type].nil? || gitolite_users[type].empty?
      end


      def merge_permissions(current_permissions, old_permissions)
        merge_permissions = {}
        merge_permissions['RW+'] = {}
        merge_permissions['RW'] = {}
        merge_permissions['R'] = {}

        current_permissions.each do |perm, branch_settings|
          branch_settings.each do |branch, user_list|
            if user_list.any?
              if !merge_permissions[perm].has_key?(branch)
                merge_permissions[perm][branch] = []
              end
              merge_permissions[perm][branch] += user_list
            end
          end
        end

        old_permissions.each do |perm, branch_settings|
          branch_settings.each do |branch, user_list|
            if user_list.any?
              if !merge_permissions[perm].has_key?(branch)
                merge_permissions[perm][branch] = []
              end
              merge_permissions[perm][branch] += user_list
            end
          end
        end

        merge_permissions.each do |perm, branch_settings|
          merge_permissions.delete(perm) if merge_permissions[perm].empty?
        end

        merge_permissions
      end

  end
end
