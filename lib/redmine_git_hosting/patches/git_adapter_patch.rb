module RedmineGitHosting
  module Patches
    module GitAdapterPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            begin
              alias_method_chain :sq_bin,         :git_hosting
              begin
                alias_method_chain :client_command, :git_hosting
              rescue Exception => e
                GitHosting.logger.warn e.message
              end
            rescue Exception => e
              # Hm.... Might be Redmine version < 1.2 (i.e. 1.1).  Try redefining GIT_BIN.
              GitHosting.logger.warn "Seems to be early version of Redmine(1.1?), try redefining GIT_BIN."
              GitHosting.logger.warn e.message
              Redmine::Scm::Adapters::GitAdapter::GIT_BIN = GitHosting.git_cmd_runner
            end
          end

          begin
            alias_method_chain :git_cmd, :git_hosting
          rescue
            # Hm... might be pre-1.4, where :git_cmd => :scm_cmd
            alias_method_chain :scm_cmd, :git_hosting rescue nil
            alias_method :git_cmd, :git_cmd_with_git_hosting
          end
        end

      end


      module ClassMethods

        def sq_bin_with_git_hosting
          return Redmine::Scm::Adapters::GitAdapter::shell_quote(GitHosting.git_cmd_runner)
        end

        def client_command_with_git_hosting
          return GitHosting.git_cmd_runner
        end

      end


      module InstanceMethods

        private

        # Pre-1.4 command syntax
        def scm_cmd_with_git_hosting(*args, &block)
          git_cmd_with_git_hosting(args, &block)
        end

        # Post-1.4 command syntax
        def git_cmd_with_git_hosting(args, options = {}, &block)
          repo_path = root_url || url
          full_args = [GitHosting.git_cmd_runner, '--git-dir', repo_path]
          if self.class.client_version_above?([1, 7, 2])
            full_args << '-c' << 'core.quotepath=false'
            full_args << '-c' << 'log.decorate=no'
          end
          full_args += args

          cmd_str = full_args.map { |e| shell_quote e.to_s }.join(' ')

          # Compute string from repo_path that should be same as: repo.git_label(:assume_unique=>false)
          # If only we had access to the repo (we don't).
          repo_id = Repository.repo_path_to_git_label(repo_path)

          # Insert cache between shell execution and caller
          # repo_path argument used to identify cache entries
          GitHostingCache.execute(cmd_str, repo_id, options, &block)
        end

      end

    end
  end
end

unless Redmine::Scm::Adapters::GitAdapter.included_modules.include?(RedmineGitHosting::Patches::GitAdapterPatch)
  Redmine::Scm::Adapters::GitAdapter.send(:include, RedmineGitHosting::Patches::GitAdapterPatch)
end
