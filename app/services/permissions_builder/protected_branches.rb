module PermissionsBuilder
  class ProtectedBranches < Standard


    def build
      puts YAML::dump(gitolite_users)

      # Build permissions
      build_permissions

      # Build protected branches permissions
      build_protected_branch_permissions

      # Return them
      [merge_permissions(permissions, old_permissions)]
    end


    def build_protected_branch_permissions
      ## http://gitolite.com/gitolite/rules.html
      ## The refex field is ignored for read check.
      ## (Git does not support distinguishing one ref from another for access control during read operations).

      repository.protected_branches.each do |branch|
        case branch.permissions
        when 'RW+'
          @permissions['RW+'][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
        when 'RW'
          @permissions['RW'][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
        end
      end

      @permissions['RW+']['personal/USER/'] = gitolite_users[:developer_team] unless has_no_users?(:developer_team)
    end

  end
end
