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


    def build_permissions
      @permissions['RW+'][''] = gitolite_users[:rewind_users] unless gitolite_users[:rewind_users].empty?
      @permissions['RW']['']  = gitolite_users[:write_users]  unless gitolite_users[:write_users].empty?
      @permissions['R']['']   = gitolite_users[:read_users]   unless gitolite_users[:read_users].empty?
    end

  end
end
