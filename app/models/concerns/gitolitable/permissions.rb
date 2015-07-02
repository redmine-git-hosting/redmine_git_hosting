module Gitolitable
  module Permissions
    extend ActiveSupport::Concern

    def build_gitolite_permissions(old_perms = {})
      permissions_builder.build(self, gitolite_users, old_perms)
    end


    def backup_gitolite_permissions(gitolite_repo_conf)
      protected_branches_available? ? {} : PermissionsBuilder::Base.get_permissions(gitolite_repo_conf)
    end


    private


      def permissions_builder
        if protected_branches_available?
          PermissionsBuilder::ProtectedBranches
        else
          PermissionsBuilder::Standard
        end
      end

  end
end
