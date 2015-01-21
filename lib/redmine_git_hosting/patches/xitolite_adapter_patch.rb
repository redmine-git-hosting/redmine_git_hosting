require_dependency 'redmine/scm/adapters/xitolite_adapter'

module RedmineGitHosting
  module Patches
    module XitoliteAdapterPatch

      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            alias_method_chain :client_command,                :git_hosting
            alias_method_chain :scm_version_from_command_line, :git_hosting
          end

          alias_method_chain :git_cmd, :git_hosting
        end

      end


      module ClassMethods

        def client_command_with_git_hosting
          @@bin ||= 'git (with sudo)'
        end


        def scm_version_from_command_line_with_git_hosting
          RedmineGitHosting::Commands.git_version
        end

      end


      module InstanceMethods

        def changed_files(path = nil, rev = 'HEAD')
          path ||= ''
          cmd_args = []
          cmd_args << 'log' << '--no-color' << '--pretty=format:%cd' << '--name-status' << '-1' << rev
          cmd_args << '--' <<  scm_iconv(@path_encoding, 'UTF-8', path) unless path.empty?
          changed_files = []
          git_cmd(cmd_args) do |io|
            io.each_line do |line|
              changed_files << line
            end
          end
          changed_files
        end


        # Override the original method to accept options hash
        # which may contain *bypass_cache* flag and pass the options hash to *git_cmd*.
        #
        def diff(path, identifier_from, identifier_to = nil, opts = {})
          path ||= ''
          cmd_args = []
          if identifier_to
            cmd_args << "diff" << "--no-color" << identifier_to << identifier_from
          else
            cmd_args << "show" << "--no-color" << identifier_from
          end
          cmd_args << "--" << scm_iconv(@path_encoding, 'UTF-8', path) unless path.empty?
          diff = []
          git_cmd(cmd_args, opts) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          diff
        rescue ScmCommandAborted
          nil
        end


        # Monkey patch *tags* method to fix http://www.redmine.org/issues/18923
        #
        def tags
          return @tags if !@tags.nil?
          @tags = []
          cmd_args = %w|tag|
          git_cmd(cmd_args) do |io|
            @tags = io.readlines.sort!.map{ |t| t.strip }
          end
          @tags
        rescue ScmCommandAborted
          nil
        end


        def rev_list(revision, args)
          cmd_args = ['rev-list', *args, revision]
          git_cmd(cmd_args) do |io|
            @revisions_list = io.readlines.map{ |t| t.strip }
          end
          @revisions_list
        rescue ScmCommandAborted
          []
        end


        def rev_parse(revision)
          cmd_args = ['rev-parse', '--quiet', '--verify', revision]
          git_cmd(cmd_args) do |io|
            @parsed_revision = io.readlines.map{ |t| t.strip }.first
          end
          @parsed_revision
        rescue ScmCommandAborted
          nil
        end


        def archive(revision, format)
          cmd_args = ['archive']
          case format
          when 'tar' then
            cmd_args << '--format=tar'
          when 'tar.gz' then
            cmd_args << '--format=tar.gz'
            cmd_args << '-7'
          when 'zip' then
            cmd_args << '--format=zip'
            cmd_args << '-7'
          else
            cmd_args << '--format=tar'
          end
          cmd_args << revision
          git_cmd(cmd_args, bypass_cache: true) do |io|
            io.binmode
            @content = io.read
          end
          @content
        rescue ScmCommandAborted
          nil
        end


        def mirror_push(mirror_url, branch = nil, args = [])
          cmd_args = git_mirror_cmd.concat(['push', *args, mirror_url, branch]).compact
          cmd = cmd_args.shift
          RedmineGitHosting::Utils.capture(cmd, cmd_args, {merge_output: true})
        end


        private


          def logger
            RedmineGitHosting.logger
          end


          def git_cmd_with_git_hosting(args, options = {}, &block)
            # Get options
            bypass_cache = options.delete(:bypass_cache){ false }

            # Build git command line
            cmd_str = prepare_command(args)

            # Insert cache between shell execution and caller
            if !git_cache_id.nil? && git_cache_enabled? && !bypass_cache
              RedmineGitHosting::ShellRedirector.execute(cmd_str, git_cache_id, options, &block)
            else
              Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str, options, &block)
            end
          end


          def prepare_command(args)
            # Get our basics args
            full_args = base_args
            # Concat with Redmine args
            full_args += args
            # Quote args
            cmd_str = full_args.map { |e| shell_quote e.to_s }.join(' ')
          end


          # Compute string from repo_path that should be same as: repo.git_cache_id
          # If only we had access to the repo (we don't).
          # We perform caching here to speed this up, since this function gets called
          # many times during the course of a repository lookup.
          def git_cache_id
            logger.debug("Lookup for git_cache_id with repository path '#{repo_path}' ... ")
            @git_cache_id ||= Repository::Xitolite.repo_path_to_git_cache_id(repo_path)
            logger.warn("Unable to find git_cache_id for '#{repo_path}', bypass cache... ") if @git_cache_id.nil?
            @git_cache_id
          end


          def base_args
            RedmineGitHosting::Commands.sudo_git_args_for_repo(repo_path).concat(git_args)
          end


          def git_mirror_cmd
            RedmineGitHosting::Commands.sudo_git_args_for_repo(repo_path, git_push_args)
          end


          def git_push_args
            [ 'env', "GIT_SSH=#{RedmineGitHosting::Config.gitolite_mirroring_script}" ]
          end


          def repo_path
            root_url || url
          end


          def git_args
            ['-c', 'core.quotepath=false', '-c', 'log.decorate=no'] if self.class.client_version_above?([1, 7, 2])
          end


          def git_cache_enabled?
            RedmineGitHosting::Config.gitolite_cache_max_time > 0
          end

      end

    end
  end
end

unless Redmine::Scm::Adapters::XitoliteAdapter.included_modules.include?(RedmineGitHosting::Patches::XitoliteAdapterPatch)
  Redmine::Scm::Adapters::XitoliteAdapter.send(:include, RedmineGitHosting::Patches::XitoliteAdapterPatch)
end
