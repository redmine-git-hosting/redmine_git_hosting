# frozen_string_literal: true

module PermissionsBuilder
  class Base
    attr_reader :repository, :gitolite_users, :old_permissions

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

    def no_users?(type)
      gitolite_users[type].blank?
    end
  end
end
