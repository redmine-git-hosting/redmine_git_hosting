module RedmineGitHosting
  module Patches
    module RepositoryPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            alias_method_chain :factory,          :git_hosting
            alias_method_chain :fetch_changesets, :git_hosting
          end

          has_one  :git_extra,        :foreign_key => 'repository_id', :class_name => 'RepositoryGitExtra', :dependent => :destroy
          has_one  :git_notification, :foreign_key => 'repository_id', :class_name => 'RepositoryGitNotification', :dependent => :destroy

          has_many :repository_mirrors,                :dependent => :destroy
          has_many :repository_post_receive_urls,      :dependent => :destroy
          has_many :repository_deployment_credentials, :dependent => :destroy

          # Place additional constraints on repository identifiers
          # because of multi repos
          validate :additional_ident_constraints

          before_destroy :clean_cache, prepend: true
        end
      end


      module ClassMethods

        def factory_with_git_hosting(klass_name, *args)
          new_repo = factory_without_git_hosting(klass_name, *args)
          if new_repo.is_a?(Repository::Git)
            if new_repo.extra.nil?
              # Note that this autoinitializes default values and hook key
              GitHosting.logger.error "Automatic initialization of RepositoryGitExtra failed for #{self.project.to_s}"
            end
          end
          return new_repo
        end


        def fetch_changesets_with_git_hosting(&block)
          # Do actual update
          fetch_changesets_without_git_hosting(&block)
        end


        # Translate repository path into a unique ID for use in caching of git commands.
        #
        # Return value is from repo.git_label(:assume_unique=>false) to be independent
        # of current value of repo_ident_unique?.
        #
        # We perform caching here to speed this up, since this function gets called
        # many times during the course of a repository lookup.
        @@cached_path = nil
        @@cached_id = nil
        def repo_path_to_git_label(repo_path)
          # Return cached value if pesent
          return @@cached_id if @@cached_path == repo_path

          repo = Repository.find_by_path(repo_path, :parse_ext => true)
          if repo
            # Cache translated id path, return id
            @@cached_path = repo_path
            @@cached_id = repo.git_label(:assume_unique => false)
          else
            # Hm... clear cache, return nil
            @@cached_path = nil
            @@cached_id = nil
          end
        end


        # Parse a path of the form <proj1>/<proj2>/<proj3>/<repo> and return the specified
        # repository.  If either 'repo_ident_unique?' is true or the <repo> is a project
        # identifier, just return the last component.  Otherwise,
        # use the immediate parent (<proj3>) to try to identify the repo.
        #
        # Flags:
        #  :loose => true : Try to identify corresponding repo even if path is not quite correct
        #
        # Note that the :loose flag is used when interpreting the contents of the
        # repository.  If switching back and forth between the "repo_ident_unique?"
        # form, it will still identify the repository (as long as there are not more than
        # one repo with the same identifier.
        #
        # Note about pre Redmine 1.4 -- only look at last component and try to match to a path.
        # If that doesn't work, return nil.
        def find_by_path(path, flags={})
          if parseit = path.match(/^.*?(([^\/]+)\/)?([^\/]+?)(\.git)?$/)
            if proj = Project.find_by_identifier(parseit[3])
              # return default or first repo with blank identifier (or first Git repo--very rare?)
              proj && (proj.repository || proj.repo_blank_ident || proj.gitolite_repos.first)
            elsif repo_ident_unique? || flags[:loose] && parseit[2].nil?
              find_by_identifier(parseit[3])
            elsif parseit[2] && proj = Project.find_by_identifier(parseit[2])
              find_by_identifier_and_project_id(parseit[3],proj.id) ||
              flags[:loose] && find_by_identifier(parseit[3]) || nil
            else
              nil
            end
          else
            nil
          end
        end


        # Repo ident unique
        def repo_ident_unique?
          RedmineGitolite::Config.unique_repo_identifier?
        end


        def fetch_changesets_for_project(project_id)
          project = Project.find_by_identifier(project_id)
          if project
            # Fetch changesets for all repos for project (works for 1.4)
            Repository.find_all_by_project_id(project.id).each do |repository|
              begin
                repository.fetch_changesets
              rescue Redmine::Scm::Adapters::CommandFailed => e
                GitHosting.logger.error "Error during fetching changesets : #{e.message}"
              end
            end
          end
        end

      end


      module InstanceMethods

        # New version of extra() -- construct extra association if missing
        def extra
          retval = self.git_extra
          if retval.nil?
            retval = RepositoryGitExtra.new()
            self.git_extra = retval  # Should save object...
          end
          retval
        end


        def extra=(new_extra_struct)
          self.git_extra = (new_extra_struct)
        end


        # If repo identifiers unique, identifier forms unique label
        # Else, use directory notation: <project identifier>/<repo identifier>
        def git_label(flags=nil)
          isunique = (flags ? flags[:assume_unique] : self.class.repo_ident_unique?)
          if identifier.blank?
            # Should only happen with one repo/project (the default)
            project.identifier
          elsif isunique
            identifier
          else
            #~ mylabel = "#{project.identifier}/#{identifier}"
            git_name
          end
        end


        # This is the (possibly non-unique) basename for the git repository
        def git_name
          identifier.blank? ? project.identifier : identifier
        end


        def ssh_url
          ssh_user_login   = RedmineGitolite::Config.gitolite_user
          git_ssh_domain   = !RedmineGitolite::Config.ssh_server_domain.empty? ? RedmineGitolite::Config.ssh_server_domain : '<empty value, contact your Administrator>'
          git_hosting_path = "#{GitHosting.git_access_url(self)}.git"
          return "ssh://#{ssh_user_login}@#{git_ssh_domain}/#{git_hosting_path}"
        end


        def http_url
          http_server_domain  = !RedmineGitolite::Config.http_server_domain.empty?  ? RedmineGitolite::Config.http_server_domain  : '<empty value, contact your Administrator>'
          http_access_path    = "#{GitHosting.http_access_url(self)}.git"
          http_user_login     = User.current.anonymous? ? "" : "#{User.current.login}@"
          return "http://#{http_user_login}#{http_server_domain}/#{http_access_path}"
        end


        def https_url
          https_server_domain = !RedmineGitolite::Config.https_server_domain.empty? ? RedmineGitolite::Config.https_server_domain : '<empty value, contact your Administrator>'
          http_access_path    = "#{GitHosting.http_access_url(self)}.git"
          http_user_login     = User.current.anonymous? ? "" : "#{User.current.login}@"
          return "https://#{http_user_login}#{https_server_domain}/#{http_access_path}"
        end


        def git_url
          git_ssh_domain   = !RedmineGitolite::Config.ssh_server_domain.empty? ? RedmineGitolite::Config.ssh_server_domain : '<empty value, contact your Administrator>'
          git_hosting_path = "#{GitHosting.git_access_url(self)}.git"
          return "git://#{git_ssh_domain}/#{git_hosting_path}"
        end


        def available_urls
          hash = {}

          commiter = User.current.allowed_to?(:commit_access, project) ? 'true' : 'false'

          ssh_access = {
            :url      => self.ssh_url,
            :commiter => commiter
          }

          https_access = {
            :url      => self.https_url,
            :commiter => commiter
          }

          ## Unsecure channel (clear password), commit is disabled
          http_access = {
            :url      => self.http_url,
            :commiter => 'false'
          }

          git_access = {
            :url      => self.git_url,
            :commiter => 'false'
          }

          if !User.current.anonymous?
            if User.current.allowed_to?(:create_gitolite_ssh_key, nil, :global => true)
              hash[:ssh] = ssh_access
            end
          end

          if self.extra[:git_http] == 1
            hash[:https] = https_access
          end

          if self.extra[:git_http] == 2
            hash[:https] = https_access
            hash[:http] = http_access
          end

          if self.extra[:git_http] == 3
            hash[:http] = http_access
          end

          if self.project.is_public && self.extra[:git_daemon] == 1
            hash[:git] = git_access
          end

          return hash
        end


        def mailing_list_default_users
          default_users = self.project.member_principals.map(&:user).compact.uniq
          default_users = default_users.select{|user| user.allowed_to?(:receive_git_notifications, self.project)}.map(&:mail)
          return default_users.uniq.sort
        end


        def mailing_list_effective
          mailing_list = {}

          # First collect all project users
          default_users = mailing_list_default_users
          if !default_users.empty?
            default_users.each do |mail|
              mailing_list[mail] = :project
            end
          end

          # Then add global include list
          if !RedmineGitolite::Config.gitolite_notify_global_include.empty?
            RedmineGitolite::Config.gitolite_notify_global_include.sort.each do |mail|
              mailing_list[mail] = :global
            end
          end

          # Then filter
          mailing_list = filter_list(mailing_list)

          # Then add local include list
          if !self.git_notification.nil? && !self.git_notification.include_list.empty?
            self.git_notification.include_list.sort.each do |mail|
              mailing_list[mail] = :local
            end
          end

          return mailing_list
        end


        def mailing_list_params
          if !self.git_notification.nil? && !self.git_notification.prefix.empty?
            email_prefix = self.git_notification.prefix
          else
            email_prefix = RedmineGitolite::Config.gitolite_notify_global_prefix
          end

          if !self.git_notification.nil? && !self.git_notification.sender_address.empty?
            sender_address = self.git_notification.sender_address
          else
            sender_address = RedmineGitolite::Config.gitolite_notify_global_sender_address
          end

          params = {
            :mailing_list   => mailing_list_effective,
            :email_prefix   => email_prefix,
            :sender_address => sender_address,
          }

          return params
        end


        private


        def filter_list(mail_list)
          mailing_list = {}
          exclude_list = []

          # Build exclusion list
          if !RedmineGitolite::Config.gitolite_notify_global_exclude.empty?
            exclude_list = exclude_list + RedmineGitolite::Config.gitolite_notify_global_exclude
          end

          if !self.git_notification.nil? && !self.git_notification.exclude_list.empty?
            exclude_list = exclude_list + self.git_notification.exclude_list
          end

          exclude_list = exclude_list.uniq.sort

          mail_list.each do |mail, from|
            mailing_list[mail] = from unless exclude_list.include?(mail)
          end

          return mailing_list
        end


        # Check several aspects of repository identifier (only for Redmine 1.4+)
        # 1) cannot equal identifier of any project
        # 2) if repo_ident_unique? make sure that repo identifier is globally unique
        # 3) cannot make this repo the default if there will be some other repo with blank identifier
        def additional_ident_constraints
          return if !self.is_a?(Repository::Git)

          if !identifier.blank? && (new_record? || identifier_changed?)
            if Project.find_by_identifier(identifier)
              errors.add(:identifier, :ident_cannot_equal_project)
            end

            # See if a repo for another project has the same identifier (existing validations already check for current project)
            if self.class.repo_ident_unique? && Repository.find_by_identifier(identifier, :conditions => ["project_id <> ?", project.id])
              errors.add(:identifier, :ident_not_unique)
            end
          end

          unless new_record?
            # Make sure identifier hasn't changed.  Allow null and blank
            # Note that simply using identifier_changed doesn't seem to work
            # if the identifier was "NULL" but the new identifier is ""
            if (identifier_was.blank? && !identifier.blank? ||
              !identifier_was.blank? && identifier_changed?)
              errors.add(:identifier, :cannot_change) if identifier_changed?
            end
          end

          if project && (is_default? || set_as_default?)
            # Need to make sure that we don't take the default slot away from a sibling repo with blank identifier
            possibles = Repository.find_all_by_project_id(project.id, :conditions => ["identifier = '' or identifier is null"])
            if possibles.any? && (new_record? || possibles.detect{|x| x.id != id})
              errors.add(:base, :blank_default_exists)
            end
          end
        end


        def clean_cache
          if self.is_a?(Repository::Git)
            RedmineGitolite::Log.get_logger(:git_cache).info "Clean cache before delete repository '#{GitHosting.repository_name(self)}'"
            RedmineGitolite::Cache.clear_cache_for_repository(self)
          end
        end

      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
