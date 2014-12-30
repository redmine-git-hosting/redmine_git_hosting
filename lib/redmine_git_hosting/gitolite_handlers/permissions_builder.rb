module RedmineGitHosting
  module GitoliteHandlers
    class PermissionsBuilder

      attr_reader :repository
      attr_reader :project
      attr_reader :users

      attr_reader :rewind
      attr_reader :write
      attr_reader :read

      attr_reader :permissions
      attr_reader :old_permissions


      def initialize(repository, old_permissions)
        @repository = repository
        @project    = repository.project
        @users      = repository.project.member_principals.map(&:user).compact.uniq

        @rewind     = []
        @write      = []
        @read       = []

        @permissions        = {}
        @permissions["RW+"] = {}
        @permissions["RW"]  = {}
        @permissions["R"]   = {}
        @old_permissions    = old_permissions
      end


      class << self

        SKIP_USERS = [ 'gitweb', 'daemon', 'DUMMY_REDMINE_KEY', 'REDMINE_ARCHIVED_PROJECT', 'REDMINE_CLOSED_PROJECT' ]

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

          return old_permissions
        end


        def gitolite_identifier_prefix
          RedmineGitHosting::Config.gitolite_identifier_prefix
        end

      end


      def call
        # Build permissions
        build_permissions
        # Return them
        [merge_permissions(permissions, old_permissions)]
      end


      private


        def build_permissions
          # First build_users_list
          build_users_list

          # Add protected_branches permissions if needed
          build_protected_branch_permissions if project.active? && repository.extra[:protected_branch]

          # Add normal permissions
          build_standard_permissions
        end


        def build_users_list
          if project.active?
            # Add project users
            @rewind = rewind_users
            @write  = write_users
            @read   = read_users
            # Add Řepository Deployment keys
            set_deploy_keys
            # Add other users
            set_dummy_keys
          elsif project.archived?
            @read << "REDMINE_ARCHIVED_PROJECT"
          else
            @read = all_read
            @read << "REDMINE_CLOSED_PROJECT"
          end
        end


        def build_standard_permissions
          @permissions["RW+"][""] = rewind unless rewind.empty?
          @permissions["RW"][""]  = write unless write.empty?
          @permissions["R"][""]   = read unless read.empty?
        end


        def build_protected_branch_permissions
          ## http://gitolite.com/gitolite/rules.html
          ## The refex field is ignored for read check.
          ## (Git does not support distinguishing one ref from another for access control during read operations).

          repository.protected_branches.each do |branch|
            case branch.permissions
            when 'RW+'
              @permissions["RW+"][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
            when 'RW'
              @permissions["RW"][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
            end
          end

          @permissions["RW+"]['personal/USER/'] = developer_team.sort unless developer_team.empty?
        end


        def rewind_users
          @rewind_users ||= users.select{ |u| u.allowed_to?(:manage_repository, project) }.map{ |u| u.gitolite_identifier }.sort
        end


        def write_users
          @write_users ||= users.select{ |u| u.allowed_to?(:commit_access, project) }.map{ |u| u.gitolite_identifier }.sort - rewind_users
        end


        def read_users
          @read_users ||= users.select{ |u| u.allowed_to?(:view_changesets, project) }.map{ |u| u.gitolite_identifier }.sort - rewind_users - write_users
        end


        def developer_team
          @developer_team ||= rewind_users + write_users
        end


        def all_read
          @all_read ||= rewind_users + write_users + read_users
        end


        def set_deploy_keys
          ## DEPLOY KEY
          repository.deployment_credentials.active.each do |cred|
            if cred.perm == "RW+"
              @rewind << cred.gitolite_public_key.owner
            elsif cred.perm == "R"
              @read << cred.gitolite_public_key.owner
            end
          end
        end


        def set_dummy_keys
          @read << "DUMMY_REDMINE_KEY" if @read.empty? && @write.empty? && @rewind.empty?
          @read << "gitweb" if User.anonymous.allowed_to?(:browse_repository, project) && repository.extra[:git_http] != 0
          @read << "daemon" if User.anonymous.allowed_to?(:view_changesets, project) && repository.extra[:git_daemon]
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

          return merge_permissions
        end

    end
  end
end
