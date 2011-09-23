module GitHosting
	module Patches
		module GitAdapterPatch

			def self.included(base)
				base.class_eval do
					unloadable
				end

				begin
					base.send(:alias_method_chain, :scm_cmd, :sudo)
				rescue Exception =>e
				end

				base.extend(ClassMethods)
				base.class_eval do
					class << self
						alias_method_chain :sq_bin, :sudo
						begin
							alias_method_chain :client_command, :sudo
						rescue Exception =>e
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


			def scm_cmd_with_sudo(*args, &block)

				max_cache_time     = (Setting.plugin_redmine_git_hosting['gitCacheMaxTime']).to_i             # in seconds, default = 60
				max_cache_elements = (Setting.plugin_redmine_git_hosting['gitCacheMaxElements']).to_i         # default = 100
				max_cache_size     = (Setting.plugin_redmine_git_hosting['gitCacheMaxSize']).to_i*1024*1024   # In MB, default = 16MB, converted to bytes

				repo_path = root_url || url
				full_args = [GitHosting::git_exec(), '--git-dir', repo_path]
				if self.class.client_version_above?([1, 7, 2])
					full_args << '-c' << 'core.quotepath=false'
					full_args << '-c' << 'log.decorate=no'
				end
				full_args += args

				cmd_str=full_args.map { |e| shell_quote e.to_s }.join(' ')
				out=nil
				retio = nil
				cached=GitCache.find_by_command(cmd_str)
				if cached != nil
					cur_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
					if cur_time.to_i - cached.created_at.to_i < max_cache_time || max_cache_time < 0
						out = cached.command_output == nil ? "" : cached.command_output
						#File.open("/tmp/command_output.txt", "a") { |f| f.write("COMMAND:#{cmd_str}\n#{out}\n") }
					else
						GitCache.destroy(cached.id)
					end
				end
				if out == nil
					shellout(cmd_str) do |io|
						out = io.read(max_cache_size + 1)
					end
					out = out == nil ? "" : out

					if $? && $?.exitstatus != 0
						raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "git exited with non-zero status: #{$?.exitstatus}"
					elsif out.length <= max_cache_size
						proj_id=repo_path.gsub(/\.git$/, "").gsub(/^.*\//, "")
						gitc = GitCache.create( :command=>cmd_str, :command_output=>out, :proj_identifier=>proj_id )
						gitc.save
						if GitCache.count > max_cache_elements && max_cache_elements >= 0
							oldest = GitCache.find(:last, :order => "created_at DESC")
							GitCache.destroy(oldest.id)
						end
						#File.open("/tmp/non_cached.txt", "a") { |f| f.write("COMMAND:#{cmd_str}\n#{out}\n") }
					else
						retio = shellout(cmd_str, &block)
						if $? && $?.exitstatus != 0
							raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "git exited with non-zero status: #{$?.exitstatus}"
						end

					end
				end

				if retio == nil
					retio = StringIO.new(string=out)
					if block_given?
						block.call(retio)
					end
				end
				retio
			end


		end
	end
end
