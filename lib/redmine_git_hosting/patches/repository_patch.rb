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

          has_many :cia_notifications, :foreign_key =>'repository_id', :class_name => 'GitCiaNotification', :dependent => :destroy, :extend => RedmineGitHosting::Patches::RepositoryCiaFilters::FilterMethods
          has_many :repository_mirrors,                :dependent => :destroy
          has_many :repository_post_receive_urls,      :dependent => :destroy
          has_many :repository_deployment_credentials, :dependent => :destroy

          # Place additional constraints on repository identifiers
          # Only for Redmine 1.4+
          if GitHosting.multi_repos?
            validate :additional_ident_constraints
          end

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
          # Turn of updates during repository update
          GitHostingObserver.set_update_active(false)

          # Do actual update
          fetch_changesets_without_git_hosting(&block)

          # Reenable updates to perform a sync of all projects
          GitHostingObserver.set_update_active(:resync_all)
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
            if proj = Project.find_by_identifier(parseit[3]) || !GitHosting.multi_repos?
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


        # Repo ident unique (definitely true if Redmine < 1.4)
        def repo_ident_unique?
          !GitHosting.multi_repos? || GitHostingConf.unique_repo_identifier?
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
            # Construct new extra structure, followed by updating hooks (if necessary)
            GitHostingObserver.set_update_active(false)

            retval = RepositoryGitExtra.new()
            self.git_extra = retval  # Should save object...

            # If self.project != nil, trigger repair of hooks
            GitHostingObserver.set_update_active(true, self.project, :resync_hooks => true)
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
            mylabel = "#{project.identifier}/#{identifier}"
          end
        end


        # This is the (possibly non-unique) basename for the git repository
        def git_name
          (!GitHosting.multi_repos? || identifier.blank?) ? project.identifier : identifier
        end


        def available_urls
          hash = Hash.new

          http_server_domain  = !GitHostingConf.http_server_domain.empty?  ? GitHostingConf.http_server_domain  : '<empty value, contact your Administrator>'
          https_server_domain = !GitHostingConf.https_server_domain.empty? ? GitHostingConf.https_server_domain : '<empty value, contact your Administrator>'
          http_access_path    = "#{GitHosting.http_access_url(self)}.git"

          http_user_login     = User.current.anonymous? ? "" : "#{User.current.login}@"
          ssh_user_login      = GitHostingConf.gitolite_user

          http_url            = "http://#{http_user_login}#{http_server_domain}/#{http_access_path}"
          https_url           = "https://#{http_user_login}#{http_server_domain}/#{http_access_path}"

          git_ssh_domain      = !GitHostingConf.ssh_server_domain.empty? ? GitHostingConf.ssh_server_domain : '<empty value, contact your Administrator>'
          git_hosting_path    = "#{GitHosting.git_access_url(self)}.git"

          commiter            = User.current.allowed_to?(:commit_access, project) ? "true" : "false"

          ssh_access = {
            :url      => "ssh://#{ssh_user_login}@#{git_ssh_domain}/#{git_hosting_path}",
            :commiter => commiter
          }

          http_access = {
            :url      => http_url,
            :commiter => commiter
          }

          https_access = {
            :url      => https_url,
            :commiter => commiter
          }

          git_access = {
            :url      => "git://#{git_ssh_domain}/#{git_hosting_path}",
            :commiter => false
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
            hash[:http] = http_access
            hash[:https] = https_access
          end

          if self.extra[:git_http] == 3
            hash[:http] = http_access
          end

          if self.project.is_public && self.extra[:git_daemon] == 1
            hash[:git] = git_access
          end

          return hash
        end


        private


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

      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
