module RedmineGitHosting
  module Patches
    module RepositoryPatch

      module ClassMethods

        # Repo ident unique (definitely true if Redmine < 1.4)
        def repo_ident_unique?
          !GitHosting.multi_repos? || GitHostingConf.repo_ident_unique?
        end

        # Parse a path of the form <proj1>/<proj2>/<proj3>/<repo> and return the specified
        # repository.  If either 'repo_ident_unique?' is true or the <repo> is a project
        # identifier, just return the last component.  Otherwise,
        # use the immediate parent (<proj3>) to try to identify the repo.
        #
        # Flags:
        #    :loose => true    : Try to identify corresponding repo even if
        #          path is not quite correct
        #
        # Note that the :loose flag is used when interpreting the contents of the
        # repository.  If switching back and forth between the "repo_ident_unique?"
        # form, it will still identify the repository (as long as there are not more than
        # one repo with the same identifier.
        #
        # Note about pre Redmine 1.4 -- only look at last component and try to match to a path.
        # If that doesn't work, return nil.
        def find_by_path(path,flags={})
          if parseit = path.match(/^.*?(([^\/]+)\/)?([^\/]+?)(\.git)?$/)
            if proj = Project.find_by_identifier(parseit[3]) || !GitHosting.multi_repos?
              # return default or first repo with blank identifier (or first Git repo--very rare?)
              proj && (proj.repository || proj.repo_blank_ident || proj.gl_repos.first)
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

        # Translate repository path into a unique ID for use in caching of git commands.
        #
        # Return value is from repo.git_label(:assume_unique=>false) to be independent
        # of current value of repo_ident_unique?.
        #
        # We perform caching here to speed this up, since this function gets called
        # many times during the course of a repository lookup.
        @@cached_path=nil
        @@cached_id=nil
        def repo_path_to_git_label(repo_path)
          # Return cached value if pesent
          return @@cached_id if @@cached_path==repo_path

          repo=Repository.find_by_path(repo_path, :parse_ext=>true)
          if repo
            # Cache translated id path, return id
            @@cached_path=repo_path
            @@cached_id=repo.git_label(:assume_unique=>false)
          else
            # Hm... clear cache, return nil
            @@cached_path=nil
            @@cached_id=nil
          end
        end

        def fetch_changesets_for_project(proj_identifier)
          p = Project.find_by_identifier(proj_identifier)
          if p
            # Fetch changesets for all repos for project (works for 1.4)
            Repository.find_all_by_project_id(p.id).each do |repo|
              begin
                repo.fetch_changesets
              rescue Redmine::Scm::Adapters::CommandFailed => e
                logger.error "[GitHosting] error during fetching changesets: #{e.message}"
              end
            end
          end
        end

        def factory_with_git_extra_init(klass_name, *args)
          new_repo = factory_without_git_extra_init(klass_name, *args)
          if new_repo.is_a?(Repository::Git)
            if new_repo.extra.nil?
              # Note that this autoinitializes default values and hook key
              GitHosting.logger.error "[GitHosting] Automatic initialization of git_repository_extra failed for #{self.project.to_s}"
            end
          end
          return new_repo
        end

        def fetch_changesets_with_disable_update
          # Turn of updates during repository update
          GitHostingObserver.set_update_active(false);

          # Do actual update
          fetch_changesets_without_disable_update

          # Reenable updates to perform a sync of all projects
          GitHostingObserver.set_update_active(:resync_all);
        end

      end

      module InstanceMethods

        # New version of extra() -- construct extra association if missing
        def extra
          retval = self.git_extra
          if retval.nil?
            # Construct new extra structure, followed by updating hooks (if necessary)
            GitHostingObserver.set_update_active(false);

            retval = GitRepositoryExtra.new()
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
          if !GitHosting.multi_repos? || identifier.blank?
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

        # Check several aspects of repository identifier (only for Redmine 1.4+)
        # 1) cannot equal identifier of any project
        # 2) if repo_ident_unique? make sure that repo identifier is globally unique
        # 3) cannot make this repo the default if there will be some other repo with blank identifier
        def additional_ident_constraints
          return if !self.is_a?(Repository::Git)

          if !identifier.blank? && (new_record? || identifier_changed?)
            if Project.find_by_identifier(identifier)
              errors.add(:identifier,:ident_cannot_equal_project)
            end

            # See if a repo for another project has the same identifier (existing validations already check for current project)
            if self.class.repo_ident_unique? && Repository.find_by_identifier(identifier,:conditions => ["project_id <> ?",project.id])
              errors.add(:identifier,:ident_not_unique)
            end
          end

          unless new_record?
            # Make sure identifier hasn't changed.  Allow null and blank
            # Note that simply using identifier_changed doesn't seem to work
            # if the identifier was "NULL" but the new identifier is ""
            if (identifier_was.blank? && !identifier.blank? ||
              !identifier_was.blank? && identifier_changed?)
              errors.add(:identifier,:cannot_change) if identifier_changed?
            end
          end

          if project && (is_default? || set_as_default?)
            # Need to make sure that we don't take the default slot away from a sibling repo with blank identifier
            possibles = Repository.find_all_by_project_id(project.id,:conditions => ["identifier = '' or identifier is null"])
            if possibles.any? && (new_record? || possibles.detect{|x| x.id != id})
              errors.add(:base, :blank_default_exists)
            end
          end
        end

      end

      def self.included(base)
        base.class_eval do
          unloadable

          extend(ClassMethods)
          class << self
            alias_method_chain :factory, :git_extra_init
            alias_method_chain :fetch_changesets, :disable_update
          end

          # initialize association from git repository -> git_extra
          has_one :git_extra, :foreign_key =>'repository_id', :class_name => 'GitRepositoryExtra', :dependent => :destroy

          # initialize association from git repository -> cia_notifications
          has_many :cia_notifications, :foreign_key =>'repository_id', :class_name => 'GitCiaNotification', :dependent => :destroy, :extend => RedmineGitHosting::Patches::RepositoryCiaFilters::FilterMethods

          # initialize association from repository -> deployment_credentials
          has_many :deployment_credentials, :dependent => :destroy

          # initialize association from repository -> repository mirrors
          has_many :repository_mirrors, :dependent => :destroy

          # initialize association from repository -> repository post receive urls
          has_many :repository_post_receive_urls, :dependent => :destroy

          # Place additional constraints on repository identifiers
          # Only for Redmine 1.4+
          if GitHosting.multi_repos?
            validate :additional_ident_constraints
          end

          include(InstanceMethods)
        end
      end

    end
  end
end

unless Repository.included_modules.include?(RedmineGitHosting::Patches::RepositoryPatch)
  Repository.send(:include, RedmineGitHosting::Patches::RepositoryPatch)
end
