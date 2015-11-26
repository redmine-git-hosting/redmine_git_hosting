module PermissionsBuilder
  class Standard < Base

    attr_reader :permissions


    def initialize(*args)
      super
      @permissions        = {}
      @permissions['RW+'] = {}
      @permissions['RW']  = {}
      @permissions['R']   = {}
    end


    def build
      # Build permissions
      build_permissions

      # Return them
      [merge_permissions(permissions, old_permissions)]
    end


    private


      def build_permissions
        @permissions['RW+'][''] = gitolite_users[:rewind_users] unless has_no_users?(:rewind_users)
        @permissions['RW']['']  = gitolite_users[:write_users]  unless has_no_users?(:write_users)
        @permissions['R']['']   = gitolite_users[:read_users]   unless has_no_users?(:read_users)
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
