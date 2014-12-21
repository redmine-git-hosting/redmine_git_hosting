require_dependency 'repository/git'

module RedmineGitHosting
  module Patches
    module RepositoryGitPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          has_one  :git_extra,              :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryGitExtra'
          has_one  :git_notification,       :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryGitNotification'

          has_many :mirrors,                :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryMirror'
          has_many :post_receive_urls,      :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryPostReceiveUrl'
          has_many :deployment_credentials, :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryDeploymentCredential'
          has_many :git_config_keys,        :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryGitConfigKey'
          has_many :protected_branches,     :dependent => :destroy, :foreign_key => 'repository_id', :class_name => 'RepositoryProtectedBranche'

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
          RedmineGitolite::Config.get_setting(:unique_repo_identifier, true)
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

          repo = repo_path_to_object(repo_path)

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


        def repo_path_to_object(repo_path)
          find_by_path(repo_path, :loose => true)
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
              find_by_identifier(parseit[3]) || nil
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
            options = {
              :git_http       => RedmineGitolite::Config.get_setting(:gitolite_http_by_default),
              :git_daemon     => RedmineGitolite::Config.get_setting(:gitolite_daemon_by_default, true),
              :git_notify     => RedmineGitolite::Config.get_setting(:gitolite_notify_by_default, true),
              :default_branch => 'master'
            }

            retval = RepositoryGitExtra.new(options)
            self.extra = retval  # Should save object...
          end
          retval
        end


        def extra=(extra)
          self.git_extra = extra
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
          elsif self.class.repo_ident_unique?
            identifier
          else
            "#{project.identifier}/#{identifier}"
          end
        end


        # This is the (possibly non-unique) basename for the git repository
        def redmine_name
          identifier.blank? ? project.identifier : identifier
        end


        def gitolite_repository_path
          "#{RedmineGitolite::Config.get_setting(:gitolite_global_storage_dir)}#{gitolite_repository_name}.git"
        end


        def gitolite_repository_name
          File.expand_path(File.join("./", RedmineGitolite::Config.get_setting(:gitolite_redmine_storage_dir), get_full_parent_path, git_cache_id), "/")[1..-1]
        end


        def redmine_repository_path
          File.expand_path(File.join("./", get_full_parent_path, git_cache_id), "/")[1..-1]
        end


        def new_repository_name
          gitolite_repository_name
        end


        def old_repository_name
          "#{self.url.gsub(RedmineGitolite::Config.get_setting(:gitolite_global_storage_dir), '').gsub('.git', '')}"
        end


        def http_user_login
          User.current.anonymous? ? "" : "#{User.current.login}@"
        end


        def git_access_path
          "#{gitolite_repository_name}.git"
        end


        def http_access_path
          "#{RedmineGitolite::Config.get_setting(:http_server_subdir)}#{redmine_repository_path}.git"
        end


        def ssh_url
          "ssh://#{RedmineGitolite::Config.get_setting(:gitolite_user)}@#{RedmineGitolite::Config.get_setting(:ssh_server_domain)}/#{git_access_path}"
        end


        def git_url
          "git://#{RedmineGitolite::Config.get_setting(:ssh_server_domain)}/#{git_access_path}"
        end


        def http_url
          "http://#{http_user_login}#{RedmineGitolite::Config.get_setting(:http_server_domain)}/#{http_access_path}"
        end


        def https_url
          "https://#{http_user_login}#{RedmineGitolite::Config.get_setting(:https_server_domain)}/#{http_access_path}"
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

          if project.is_public && extra[:git_daemon]
            hash[:git] = git_access
          end

          return hash
        end


        def get_full_parent_path
          return "" if !RedmineGitolite::Config.get_setting(:hierarchical_organisation, true)

          parent_parts = []

          p = project
          while p.parent
            parent_id = p.parent.identifier.to_s
            parent_parts.unshift(parent_id)
            p = p.parent
          end

          return parent_parts.join("/")
        end


        def exists_in_gitolite?
          RedmineGitolite::GitoliteWrapper.sudo_dir_exists?(gitolite_repository_path)
        end


        def gitolite_hook_key
          extra[:key]
        end


        def empty?
          if extra_info.nil? || ( !extra_info.has_key?('heads') && !extra_info.has_key?('branches') )
            return true
          else
            return false
          end
        end


        def default_list
          ::GitNotifier.new(self).default_list
        end


        def mail_mapping
          ::GitNotifier.new(self).mail_mapping
        end


        private


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

          if new_record?
            errors.add(:identifier, :ident_invalid) if identifier == 'gitolite-admin'
          else
            # Make sure identifier hasn't changed.  Allow null and blank
            # Note that simply using identifier_changed doesn't seem to work
            # if the identifier was "NULL" but the new identifier is ""
            if (identifier_was.blank? && !identifier.blank? || !identifier_was.blank? && identifier_changed?)
              errors.add(:identifier, :cannot_change)
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
