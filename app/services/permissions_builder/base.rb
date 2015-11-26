module PermissionsBuilder
  class Base

    attr_reader :repository
    attr_reader :gitolite_users
    attr_reader :old_permissions


    def initialize(repository, gitolite_users, old_permissions = {})
      @repository      = repository
      @gitolite_users  = gitolite_users
      @old_permissions = old_permissions
    end


    class << self

      def build(repository, gitolite_users, old_permissions = {})
        new(repository, gitolite_users, old_permissions).build
      end

    end


    def build
      raise NotImplementedError
    end


    private


      def has_no_users?(type)
        gitolite_users[type].nil? || gitolite_users[type].empty?
      end

  end
end
