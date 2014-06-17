module RedmineGitHosting
  module Patches
    module RepositoryGitPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          has_one  :git_extra,        :foreign_key => 'repository_id', :class_name => 'RepositoryGitExtra', :dependent => :destroy
          has_one  :git_notification, :foreign_key => 'repository_id', :class_name => 'RepositoryGitNotification', :dependent => :destroy

          has_many :repository_mirrors,                :dependent => :destroy, :foreign_key => 'repository_id'
          has_many :repository_post_receive_urls,      :dependent => :destroy, :foreign_key => 'repository_id'
          has_many :repository_deployment_credentials, :dependent => :destroy, :foreign_key => 'repository_id'
          has_many :repository_git_config_keys,        :dependent => :destroy, :foreign_key => 'repository_id'

          alias_method_chain :report_last_commit,       :git_hosting
          alias_method_chain :extra_report_last_commit, :git_hosting

          # Place additional constraints on repository identifiers
          # because of multi repos
          validate :additional_ident_constraints

          before_destroy :clean_cache, prepend: true

          before_validation  :set_git_urls
        end
      end


      module ClassMethods

        # Repo ident unique
        def repo_ident_unique?
          RedmineGitolite::ConfigRedmine.get_setting(:unique_repo_identifier, true)
        end


        def have_duplicated_identifier?
          if ((self.all.map(&:identifier).inject(Hash.new(0)) do |h, x|
              h[x] += 1 unless x.blank?
              h
            end.values.max) || 0) > 1
            # Oops -- have duplication
            return true
          else
            return false
          end
        end


        # Translate repository path into a unique ID for use in caching of git commands.
        #
        # We perform caching here to speed this up, since this function gets called
        # many times during the course of a repository lookup.
        @@cached_path = nil
        @@cached_id = nil
        def repo_path_to_git_cache_id(repo_path)
          # Return cached value if pesent
          return @@cached_id if @@cached_path == repo_path

          repo = Repository::Git.find_by_path(repo_path, :loose => true)

          if repo
            # Cache translated id path, return id
            @@cached_path = repo_path
            @@cached_id = repo.git_cache_id
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
        # Example of data captured by regex :
        # <MatchData "test/test2/test3/test4/test5.git" 1:"test4/" 2:"test4" 3:"test5" 4:".git">
        # <MatchData "blabla2.git" 1:nil 2:nil 3:"blabla2" 4:".git">

        def find_by_path(path, flags = {})
          if parseit = path.match(/^.*?(([^\/]+)\/)?([^\/]+?)(\.git)?$/)
            if proj = Project.find_by_identifier(parseit[3])
              # return default or first repo with blank identifier (or first Git repo--very rare?)
              proj && (proj.repository || proj.repo_blank_ident || proj.gitolite_repos.first)
            elsif repo_ident_unique? || flags[:loose] && parseit[2].nil?
              find_by_identifier(parseit[3])
            elsif parseit[2] && proj = Project.find_by_identifier(parseit[2])
              find_by_identifier_and_project_id(parseit[3], proj.id) ||
              flags[:loose] && find_by_identifier(parseit[3]) || nil
            else
              nil
            end
          else
            nil
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


        def report_last_commit_with_git_hosting
          # Always true
          true
        end


        def extra_report_last_commit_with_git_hosting
          # Always true
          true
        end


        # If repo identifiers unique, identifier forms unique label
        # Else, use directory notation: <project identifier>/<repo identifier>
        def git_cache_id
          if identifier.blank?
            # Should only happen with one repo/project (the default)
            project.identifier
          else
            "#{project.identifier}/#{identifier}"
          end
        end


        # This is the (possibly non-unique) basename for the git repository
        def redmine_name
          (identifier.blank? or is_default?) ? project.identifier : identifier
        end


        def gitolite_repository_path
          "#{RedmineGitolite::ConfigRedmine.get_setting(:gitolite_global_storage_dir)}#{gitolite_repository_name}.git"
        end


        def gitolite_repository_name
          File.expand_path(File.join("./", RedmineGitolite::ConfigRedmine.get_setting(:gitolite_redmine_storage_dir), get_full_parent_path, redmine_name), "/")[1..-1]
        end


        def redmine_repository_path
          File.expand_path(File.join("./", get_full_parent_path, redmine_name), "/")[1..-1]
        end


        def new_repository_name
          gitolite_repository_name
        end


        def old_repository_name
          "#{self.url.gsub(RedmineGitolite::ConfigRedmine.get_setting(:gitolite_global_storage_dir), '').gsub('.git', '')}"
        end


        def http_user_login
          User.current.anonymous? ? "" : "#{User.current.login}@"
        end


        def git_access_path
          "#{gitolite_repository_name}.git"
        end


        def http_access_path
          "#{RedmineGitolite::ConfigRedmine.get_setting(:http_server_subdir)}#{redmine_repository_path}.git"
        end


        def ssh_url
          "ssh://#{RedmineGitolite::ConfigRedmine.get_setting(:gitolite_user)}@#{RedmineGitolite::ConfigRedmine.get_setting(:ssh_server_domain)}/#{git_access_path}"
        end


        def git_url
          "git://#{RedmineGitolite::ConfigRedmine.get_setting(:ssh_server_domain)}/#{git_access_path}"
        end


        def http_url
          "http://#{http_user_login}#{RedmineGitolite::ConfigRedmine.get_setting(:http_server_domain)}/#{http_access_path}"
        end


        def https_url
          "https://#{http_user_login}#{RedmineGitolite::ConfigRedmine.get_setting(:https_server_domain)}/#{http_access_path}"
        end


        def available_urls
          hash = {}

          commiter = User.current.allowed_to?(:commit_access, project) ? 'true' : 'false'

          ssh_access = {
            :url      => ssh_url,
            :commiter => commiter
          }

          https_access = {
            :url      => https_url,
            :commiter => commiter
          }

          ## Unsecure channels (clear password), commit is disabled
          http_access = {
            :url      => http_url,
            :commiter => 'false'
          }

          git_access = {
            :url      => git_url,
            :commiter => 'false'
          }

          if !User.current.anonymous?
            if User.current.allowed_to?(:create_gitolite_ssh_key, nil, :global => true)
              hash[:ssh] = ssh_access
            end
          end

          if extra[:git_http] == 1
            hash[:https] = https_access
          end

          if extra[:git_http] == 2
            hash[:https] = https_access
            hash[:http] = http_access
          end

          if extra[:git_http] == 3
            hash[:http] = http_access
          end

          if project.is_public && extra[:git_daemon] == 1
            hash[:git] = git_access
          end

          return hash
        end


        def mailing_list_default_users
          default_users = project.member_principals.map(&:user).compact.uniq
          default_users = default_users.select{|user| user.allowed_to?(:receive_git_notifications, project)}.map(&:mail)
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
          if !RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_global_include).empty?
            RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_global_include).sort.each do |mail|
              mailing_list[mail] = :global
            end
          end

          # Then filter
          mailing_list = filter_list(mailing_list)

          # Then add local include list
          if !git_notification.nil? && !git_notification.include_list.empty?
            git_notification.include_list.sort.each do |mail|
              mailing_list[mail] = :local
            end
          end

          return mailing_list
        end


        def mailing_list_params
          if !git_notification.nil? && !git_notification.prefix.empty?
            email_prefix = git_notification.prefix
          else
            email_prefix = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_global_prefix)
          end

          if !git_notification.nil? && !git_notification.sender_address.empty?
            sender_address = git_notification.sender_address
          else
            sender_address = RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_global_sender_address)
          end

          params = {
            :mailing_list   => mailing_list_effective,
            :email_prefix   => email_prefix,
            :sender_address => sender_address,
          }

          return params
        end


        def get_full_parent_path
          return "" if !RedmineGitolite::ConfigRedmine.get_setting(:hierarchical_organisation, true)

          if self.is_default?
            parent_parts = []
          else
            parent_parts = [project.identifier.to_s]
          end

          p = project
          while p.parent
            parent_id = p.parent.identifier.to_s
            parent_parts.unshift(parent_id)
            p = p.parent
          end

          return parent_parts.join("/")
        end


        def exists_in_gitolite?
          RedmineGitolite::GitHosting.dir_exists?(gitolite_repository_path)
        end


        def gitolite_hook_key
          extra[:key]
        end


        def empty?
          if extra_info.nil? || !extra_info.has_key?('heads')
            return true
          else
            return false
          end
        end


        private


        def filter_list(mail_list)
          mailing_list = {}
          exclude_list = []

          # Build exclusion list
          if !RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_global_exclude).empty?
            exclude_list = exclude_list + RedmineGitolite::ConfigRedmine.get_setting(:gitolite_notify_global_exclude)
          end

          if !git_notification.nil? && !git_notification.exclude_list.empty?
            exclude_list = exclude_list + git_notification.exclude_list
          end

          exclude_list = exclude_list.uniq.sort

          mail_list.each do |mail, from|
            mailing_list[mail] = from unless exclude_list.include?(mail)
          end

          return mailing_list
        end


        # Set up git urls for new repositories
        def set_git_urls
          self.url = self.gitolite_repository_path if self.url.blank?
          self.root_url = self.url if self.root_url.blank?
        end


        # Check several aspects of repository identifier (only for Redmine 1.4+)
        # 1) cannot equal identifier of any project
        # 2) if repo_ident_unique? make sure that repo identifier is globally unique
        # 3) cannot make this repo the default if there will be some other repo with blank identifier
        def additional_ident_constraints
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
          RedmineGitolite::Log.get_logger(:global).info { "Clean cache before delete repository '#{gitolite_repository_name}'" }
          RedmineGitolite::Cache.clear_cache_for_repository(self)
        end

      end

    end
  end
end

unless Repository::Git.included_modules.include?(RedmineGitHosting::Patches::RepositoryGitPatch)
  Repository::Git.send(:include, RedmineGitHosting::Patches::RepositoryGitPatch)
end
