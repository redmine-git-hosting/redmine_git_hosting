module Gitolitable
  module Users
    extend ActiveSupport::Concern

    def gitolite_users
      if project.active?
        users_for_active_project
      elsif project.archived?
        users_for_archived_project
      else
        users_for_closed_project
      end
    end


    def users_for_active_project
      data = {}
      data[:rewind_users]   = rewind_users
      data[:write_users]    = write_users
      data[:read_users]     = read_users
      data[:developer_team] = developer_team
      data[:all_read]       = all_users

      # Add Řepository Deployment keys
      deployment_credentials.active.each do |cred|
        if cred.perm == 'RW+'
          data[:rewind_users] << cred.gitolite_public_key.owner
        elsif cred.perm == 'R'
          data[:read_users] << cred.gitolite_public_key.owner
        end
      end

      # Add other users
      data[:read_users] << 'DUMMY_REDMINE_KEY' if read_users.empty? && write_users.empty? && rewind_users.empty?
      data[:read_users] << 'gitweb' if git_web_available?
      data[:read_users] << 'daemon' if git_daemon_available?

      # Return users
      data
    end


    def users_for_archived_project
      data = {}
      data[:read_users] = ['REDMINE_ARCHIVED_PROJECT']
      data
    end


    def users_for_closed_project
      data = {}
      data[:read_users] = all_users
      data[:read_users] << 'REDMINE_CLOSED_PROJECT'
      data
    end


    def users
      project.member_principals.map(&:user).compact.uniq
    end


    def rewind_users
      @rewind_users ||= users.select { |u| u.allowed_to?(:manage_repository, project) }.map { |u| u.gitolite_identifier }.sort
    end


    def write_users
      @write_users ||= users.select { |u| u.allowed_to?(:commit_access, project) }.map { |u| u.gitolite_identifier }.sort - rewind_users
    end


    def read_users
      @read_users ||= users.select { |u| u.allowed_to?(:view_changesets, project) }.map { |u| u.gitolite_identifier }.sort - rewind_users - write_users
    end


    def developer_team
      @developer_team ||= (rewind_users + write_users).sort
    end


    def all_users
      @all_users ||= (rewind_users + write_users + read_users).sort
    end

  end
end
