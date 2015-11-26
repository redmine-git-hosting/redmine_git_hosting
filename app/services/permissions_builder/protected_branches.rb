module PermissionsBuilder
  class ProtectedBranches < Base

    attr_reader :permissions


    def initialize(*args)
      super
      @permissions = []
    end


    def build
      build_protected_branch_permissions
      permissions
    end


    def build_protected_branch_permissions
      repository.protected_branches.each do |branch|
        perms = {}
        perms[branch.permissions] = {}
        perms[branch.permissions][branch.path] = branch.allowed_users unless branch.allowed_users.empty?
        permissions.push(perms)
      end
    end

  end
end
