require 'redmine/scm/adapters/abstract_adapter'

# XitoliteAdapter inherits from GitAdapter but some classes which are define directly in GitAdapter are not inherited
# (GitBranch, ScmCommandAborted and maybe others) so it raises NameError exception.
# To fix this I had to reimplement (copy/past) the whole GitAdapter class in XitoliteAdapter...
# I wanted to avoid it to avoid code duplication but it seems to be the only way...

module Redmine
  module Scm
    module Adapters
      class XitoliteAdapter < AbstractAdapter

        # Git executable name
        XITOLITE_BIN = Redmine::Configuration['scm_git_command'] || "git"

        class GitBranch < Branch
          attr_accessor :is_default
        end

        class << self

          def client_command
            @@bin ||= XITOLITE_BIN
          end


          def sq_bin
            @@sq_bin ||= shell_quote_command
          end


          def client_version
            @@client_version ||= (scm_command_version || [])
          end


          def client_available
            !client_version.empty?
          end


          def scm_command_version
            scm_version = scm_version_from_command_line.dup
            if scm_version.respond_to?(:force_encoding)
              scm_version.force_encoding('ASCII-8BIT')
            end
            if m = scm_version.match(%r{\A(.*?)((\d+\.)+\d+)})
              m[2].scan(%r{\d+}).collect(&:to_i)
            end
          end


          # Change from the original method
          def scm_version_from_command_line
            RedmineGitHosting::Commands.git_version
          end

        end


        def initialize(url, root_url = nil, login = nil, password = nil, path_encoding = nil)
          super
          @path_encoding = path_encoding.blank? ? 'UTF-8' : path_encoding
        end


        def path_encoding
          @path_encoding
        end


        def info
          begin
            Info.new(root_url: url, lastrev: lastrev('', nil))
          rescue
            nil
          end
        end


        def branches
          return @branches if !@branches.nil?
          @branches = []
          cmd_args = %w|branch --no-color --verbose --no-abbrev|
          git_cmd(cmd_args) do |io|
            io.each_line do |line|
              branch_rev = line.match('\s*(\*?)\s*(.*?)\s*([0-9a-f]{40}).*$')
              bran = GitBranch.new(branch_rev[2].to_s.force_encoding(Encoding::UTF_8))
              bran.revision =  branch_rev[3]
              bran.scmid    =  branch_rev[3]
              bran.is_default = (branch_rev[1] == '*')
              @branches << bran
            end
          end
          @branches.sort!
        rescue ScmCommandAborted => e
          logger.error(e.message)
          []
        end


        def tags
          return @tags if !@tags.nil?
          @tags = []
          cmd_args = %w|tag|
          git_cmd(cmd_args) do |io|
            @tags = io.readlines.sort!.map { |t| t.strip.force_encoding(Encoding::UTF_8) }
          end
          @tags
        rescue ScmCommandAborted => e
          logger.error(e.message)
          []
        end


        def default_branch
          bras = self.branches
          return nil if bras.nil?
          default_bras = bras.select { |x| x.is_default == true }
          return default_bras.first.to_s if !default_bras.empty?
          master_bras = bras.select { |x| x.to_s == 'master' }
          master_bras.empty? ? bras.first.to_s : 'master'
        end


        def entry(path = nil, identifier = nil)
          parts = path.to_s.split(%r{[\/\\]}).select { |n| !n.blank? }
          search_path = parts[0..-2].join('/')
          search_name = parts[-1]
          if search_path.blank? && search_name.blank?
            # Root entry
            Entry.new(path: '', kind: 'dir')
          else
            # Search for the entry in the parent directory
            es = entries(search_path, identifier, report_last_commit: false)
            es ? es.detect { |e| e.name == search_name } : nil
          end
        end


        def entries(path = nil, identifier = nil, options = {})
          path ||= ''
          p = scm_iconv(@path_encoding, 'UTF-8', path)
          entries = Entries.new
          cmd_args = %w|ls-tree -l|
          cmd_args << "HEAD:#{p}"          if identifier.nil?
          cmd_args << "#{identifier}:#{p}" if identifier
          git_cmd(cmd_args) do |io|
            io.each_line do |line|
              e = line.chomp.to_s
              if e =~ /^\d+\s+(\w+)\s+([0-9a-f]{40})\s+([0-9-]+)\t(.+)$/
                type = $1
                sha  = $2
                size = $3
                name = $4
                if name.respond_to?(:force_encoding)
                  name.force_encoding(@path_encoding)
                end
                full_path = p.empty? ? name : "#{p}/#{name}"
                n      = scm_iconv('UTF-8', @path_encoding, name)
                full_p = scm_iconv('UTF-8', @path_encoding, full_path)
                entries << Entry.new({:name => n,
                 :path => full_p,
                 :kind => (type == "tree") ? 'dir' : 'file',
                 :size => (type == "tree") ? nil : size,
                 :lastrev => options[:report_last_commit] ?
                                 lastrev(full_path, identifier) : Revision.new
                }) unless entries.detect { |entry| entry.name == name }
              end
            end
          end
          entries.sort_by_name
        rescue ScmCommandAborted => e
          logger.error(e.message)
          []
        end


        def lastrev(path, rev)
          return nil if path.nil?
          cmd_args = %w|log --no-color --encoding=UTF-8 --date=iso --pretty=fuller --no-merges -n 1|
          cmd_args << rev if rev
          cmd_args << "--" << path unless path.empty?
          lines = []
          git_cmd(cmd_args) { |io| lines = io.readlines }
          begin
              id = lines[0].split[1]
              author = lines[1].match('Author:\s+(.*)$')[1]
              time = Time.parse(lines[4].match('CommitDate:\s+(.*)$')[1])

              Revision.new({
                :identifier => id,
                :scmid      => id,
                :author     => author,
                :time       => time,
                :message    => nil,
                :paths      => nil
                })
          rescue NoMethodError => e
            logger.error("The revision '#{path}' has a wrong format")
            return nil
          end
        rescue ScmCommandAborted => e
          logger.error(e.message)
          nil
        end


        def revisions(path, identifier_from, identifier_to, options = {})
          revs = Revisions.new
          cmd_args = %w|log --no-color --encoding=UTF-8 --raw --date=iso --pretty=fuller --parents --stdin|
          cmd_args << "--reverse" if options[:reverse]
          cmd_args << "-n" << "#{options[:limit].to_i}" if options[:limit]
          cmd_args << "--" << scm_iconv(@path_encoding, 'UTF-8', path) if path && !path.empty?
          revisions = []
          if identifier_from || identifier_to
            revisions << ''
            revisions[0] << "#{identifier_from}.." if identifier_from
            revisions[0] << "#{identifier_to}" if identifier_to
          else
            revisions += options[:includes] unless options[:includes].blank?
            revisions += options[:excludes].map { |r| "^#{r}" } unless options[:excludes].blank?
          end

          git_cmd(cmd_args, { write_stdin: true }) do |io|
            io.binmode
            io.puts(revisions.join("\n"))
            io.close_write

            files = []
            changeset = {}

            # 0: not parsing desc or files
            # 1: parsing desc
            # 2: parsing files
            parsing_descr = 0

            io.each_line do |line|
              if line =~ /^commit ([0-9a-f]{40})(( [0-9a-f]{40})*)$/
                key = 'commit'
                value = $1
                parents_str = $2
                if parsing_descr == 1 || parsing_descr == 2
                  parsing_descr = 0
                  revision = Revision.new({
                    :identifier => changeset[:commit],
                    :scmid      => changeset[:commit],
                    :author     => changeset[:author],
                    :time       => Time.parse(changeset[:date]),
                    :message    => changeset[:description],
                    :paths      => files,
                    :parents    => changeset[:parents]
                  })
                  if block_given?
                    yield revision
                  else
                    revs << revision
                  end
                  changeset = {}
                  files = []
                end
                changeset[:commit] = $1
                unless parents_str.nil? or parents_str == ''
                  changeset[:parents] = parents_str.strip.split(' ')
                end
              elsif (parsing_descr == 0) && line =~ /^(\w+):\s*(.*)$/
                key = $1
                value = $2
                if key == 'Author'
                  changeset[:author] = value
                elsif key == 'CommitDate'
                  changeset[:date] = value
                end
              elsif (parsing_descr == 0) && line.chomp.to_s == ''
                parsing_descr = 1
                changeset[:description] = ''
              elsif (parsing_descr == 1 || parsing_descr == 2) \
                  && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\t(.+)$/
                parsing_descr = 2
                fileaction    = $1
                filepath      = $2
                p = scm_iconv('UTF-8', @path_encoding, filepath)
                files << { action: fileaction, path: p }
              elsif (parsing_descr == 1 || parsing_descr == 2) \
                  && line =~ /^:\d+\s+\d+\s+[0-9a-f.]+\s+[0-9a-f.]+\s+(\w)\d+\s+(\S+)\t(.+)$/
                parsing_descr = 2
                fileaction    = $1
                filepath      = $3
                p = scm_iconv('UTF-8', @path_encoding, filepath)
                files << { action: fileaction, path: p }
              elsif (parsing_descr == 1) && line.chomp.to_s == ''
                parsing_descr = 2
              elsif (parsing_descr == 1)
                changeset[:description] << line[4..-1]
              end
            end

            if changeset[:commit]
              revision = Revision.new({
                :identifier => changeset[:commit],
                :scmid      => changeset[:commit],
                :author     => changeset[:author],
                :time       => Time.parse(changeset[:date]),
                :message    => changeset[:description],
                :paths      => files,
                :parents    => changeset[:parents]
              })
              if block_given?
                yield revision
              else
                revs << revision
              end
            end
          end
          revs
        rescue ScmCommandAborted => e
          err_msg = "git log error: #{e.message}"
          logger.error(err_msg)
          if block_given?
            raise CommandFailed, err_msg
          else
            revs
          end
        end


        # Override the original method to accept options hash
        # which may contain *bypass_cache* flag and pass the options hash to *git_cmd*.
        #
        def diff(path, identifier_from, identifier_to = nil, opts = {})
          path ||= ''
          cmd_args = []
          if identifier_to
            cmd_args << 'diff' << '--no-color' << identifier_to << identifier_from
          else
            cmd_args << 'show' << '--no-color' << identifier_from
          end
          cmd_args << '--' << scm_iconv(@path_encoding, 'UTF-8', path) unless path.empty?
          diff = []
          git_cmd(cmd_args, opts) do |io|
            io.each_line do |line|
              diff << line
            end
          end
          diff
        rescue ScmCommandAborted => e
          logger.error(e.message)
          nil
        end


        def annotate(path, identifier = nil)
          identifier = 'HEAD' if identifier.blank?
          cmd_args = %w|blame --encoding=UTF-8|
          cmd_args << '-p' << identifier << '--' <<  scm_iconv(@path_encoding, 'UTF-8', path)
          blame = Annotate.new
          content = nil
          git_cmd(cmd_args) { |io| io.binmode; content = io.read }
          # git annotates binary files
          return nil if binary_data?(content)
          identifier = ''
          # git shows commit author on the first occurrence only
          authors_by_commit = {}
          content.split("\n").each do |line|
            if line =~ /^([0-9a-f]{39,40})\s.*/
              identifier = $1
            elsif line =~ /^author (.+)/
              authors_by_commit[identifier] = $1.strip
            elsif line =~ /^\t(.*)/
              blame.add_line($1, Revision.new(
                                    :identifier => identifier,
                                    :revision   => identifier,
                                    :scmid      => identifier,
                                    :author     => authors_by_commit[identifier]
                                    ))
              identifier = ''
              author = ''
            end
          end
          blame
        rescue ScmCommandAborted => e
          logger.error(e.message)
          nil
        end


        def cat(path, identifier = nil)
          identifier = 'HEAD' if identifier.nil?
          cmd_args = %w|show --no-color|
          cmd_args << "#{identifier}:#{scm_iconv(@path_encoding, 'UTF-8', path)}"
          cat = nil
          git_cmd(cmd_args) do |io|
            io.binmode
            cat = io.read
          end
          cat
        rescue ScmCommandAborted => e
          logger.error(e.message)
          nil
        end


        # Added to be compatible with EmailDiff plugin
        #
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


        # Added for GitDownloadRevision
        #
        def rev_list(revision, args)
          cmd_args = ['rev-list', *args, revision]
          git_cmd(cmd_args) do |io|
            @revisions_list = io.readlines.map { |t| t.strip }
          end
          @revisions_list
        rescue ScmCommandAborted => e
          logger.error(e.message)
          []
        end


        # Added for GitDownloadRevision / GithubPayload
        #
        def rev_parse(revision)
          cmd_args = ['rev-parse', '--quiet', '--verify', revision]
          git_cmd(cmd_args) do |io|
            @parsed_revision = io.readlines.map { |t| t.strip }.first
          end
          @parsed_revision
        rescue ScmCommandAborted => e
          logger.error(e.message)
          nil
        end


        # Added for GitDownloadRevision
        #
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
        rescue ScmCommandAborted => e
          logger.error(e.message)
          nil
        end


        # Added for MirrorPush
        #
        def mirror_push(mirror_url, branch = nil, args = [])
          cmd_args = git_mirror_cmd.concat(['push', *args, mirror_url, branch]).compact
          cmd = cmd_args.shift
          RedmineGitHosting::Utils::Exec.capture(cmd, cmd_args, { merge_output: true })
        end


        class Revision < Redmine::Scm::Adapters::Revision
          # Returns the readable identifier
          def format_identifier
            identifier[0, 8]
          end
        end


        private


          def logger
            RedmineGitHosting.logger
          end


          def git_cmd(args, options = {}, &block)
            # Get options
            bypass_cache = options.delete(:bypass_cache) { false }

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
            full_args.map { |e| shell_quote(e.to_s) }.join(' ')
          end


          # Compute string from repo_path that should be same as: repo.git_cache_id
          # If only we had access to the repo (we don't).
          # We perform caching here to speed this up, since this function gets called
          # many times during the course of a repository lookup.
          def git_cache_id
            logger.debug("Lookup for git_cache_id with repository path '#{repo_path}' ... ")
            @git_cache_id ||= Repository::Xitolite.repo_path_to_git_cache_id(repo_path)
            logger.warn("Unable to find git_cache_id for '#{repo_path}', bypass cache... ") if @git_cache_id.nil?
            logger.debug("git_cache_id found : #{@git_cache_id}") if !@git_cache_id.nil?
            @git_cache_id
          end


          def base_args
            RedmineGitHosting::Commands.sudo_git_args_for_repo(repo_path).concat(git_args)
          end


          def git_mirror_cmd
            RedmineGitHosting::Commands.sudo_git_args_for_repo(repo_path, git_push_args)
          end


          def git_push_args
            ['env', "GIT_SSH=#{RedmineGitHosting::Config.gitolite_mirroring_script}"]
          end


          def repo_path
            root_url || url
          end


          def git_args
            self.class.client_version_above?([1, 7, 2]) ? ['-c', 'core.quotepath=false', '-c', 'log.decorate=no'] : []
          end


          def git_cache_enabled?
            RedmineGitHosting::Config.gitolite_cache_max_time != 0
          end

          def binary_data?(content)
            if Gem::Version.new(Redmine::VERSION.to_s) >= Gem::Version.new('3.4')
              ScmData.binary?(content)
            else
              content.is_binary_data?
            end
          end

      end
    end
  end
end
