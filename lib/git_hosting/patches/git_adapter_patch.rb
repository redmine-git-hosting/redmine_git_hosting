require_dependency 'principal'
require_dependency 'user'
require_dependency 'git_hosting'
require_dependency 'redmine/scm/adapters/git_adapter'

module GitHosting
  module Patches
    module GitAdapterPatch

      def self.included(base)
        base.class_eval do
          unloadable
        end

        begin
          base.send(:alias_method_chain, :git_cmd, :sudo)
        rescue
          # Hm... might be pre-1.4, where :git_cmd => :scm_cmd
          base.send(:alias_method_chain, :scm_cmd, :sudo) rescue nil
          base.send(:alias_method, :git_cmd, :git_cmd_with_sudo)
        end

        base.extend(ClassMethods)

        base.class_eval do
          class << self
            begin
              alias_method_chain :sq_bin, :sudo
              begin
                alias_method_chain :client_command, :sudo
              rescue Exception =>e
              end
            rescue Exception => e
              # Hm.... Might be Redmine version < 1.2 (i.e. 1.1).  Try redefining GIT_BIN.
              GitHosting.logger.warn "Seems to be early version of Redmine(1.1?), try redefining GIT_BIN."
              Redmine::Scm::Adapters::GitAdapter::GIT_BIN = GitHosting::git_exec()
            end
          end
        end

      end

      module ClassMethods

        def sq_bin_with_sudo
          return Redmine::Scm::Adapters::GitAdapter::shell_quote(GitHosting::git_exec())
        end

        def client_command_with_sudo
          return GitHosting::git_exec()
        end

      end

      # Pre-1.4 command syntax
      def scm_cmd_with_sudo(*args, &block)
        git_cmd_with_sudo(args, &block)
      end

      # Post-1.4 command syntax
      def git_cmd_with_sudo(args, options = {}, &block)
        repo_path = root_url || url
        full_args = [GitHosting::git_exec(), '--git-dir', repo_path]
        if self.class.client_version_above?([1, 7, 2])
          full_args << '-c' << 'core.quotepath=false'
          full_args << '-c' << 'log.decorate=no'
        end
        full_args += args

        cmd_str=full_args.map { |e| shell_quote e.to_s }.join(' ')

        # Compute string from repo_path that should be same as: repo.git_label(:assume_unique=>false)
        # If only we had access to the repo (we don't).
        repo_id=Repository.repo_path_to_git_label(repo_path)

        # Insert cache between shell execution and caller
        # repo_path argument used to identify cache entries
        CachedShellRedirector.execute(cmd_str,repo_id,options,&block)
      end

      # Check for latest commit (applied to this repo) and set it as a
      # limit for the oldest cached entries.  This caused cached entries
      # to be ignored/invalidated if they are older than the latest log
      # entry
      def ignore_old_cache_entries
        Rails.logger.error "Running ignore_old_cache_entries"
        # Ask for latest "commit date" on all branches
        cmd_args = %w|log --all --date=iso --format=%cd -n 1 --date=iso|
        begin
          git_cmd(cmd_args,:uncached=>true) do |io|
            # Register this latest commit time as cache limit time
            limit=Time.parse(io.readline)
            CachedShellRedirector.limit_cache(root_url||url,limit)
          end
        rescue
          # Wasn't able to ask git for limit date.  Just disable cache.
          CachedShellRedirector.clear_cache_for_repository(root_url||url)
        end
      end

    end
  end
end

# Patch in changes
Redmine::Scm::Adapters::GitAdapter.send(:include, GitHosting::Patches::GitAdapterPatch)
