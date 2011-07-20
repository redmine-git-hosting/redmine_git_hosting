require_dependency 'redmine/scm/adapters/git_adapter'
require 'stringio'

module GitHosting
	module Patches
		module GitAdapterPatch
			
			def self.included(base)
				base.class_eval do
					unloadable
				end
				
				begin			
					base.send(:alias_method_chain, :scm_cmd, :ssh)
				rescue Exception =>e
				end
				
				base.extend(ClassMethods)
				base.class_eval do
					class << self
						alias_method_chain :sq_bin, :ssh
						begin
							alias_method_chain :client_command, :ssh
						rescue Exception =>e
						end
					end
				end
			
			end
	


			module ClassMethods
				def sq_bin_with_ssh
					return Redmine::Scm::Adapters::GitAdapter::shell_quote(GitHosting::git_exec())
				end
                                def client_command_with_ssh
            				return GitHosting::git_exec()
                                end
			end

			
			
			def scm_cmd_with_ssh(*args, &block)
				
				cache_time = 60
				max_cache = 10000
				
				repo_path = root_url || url
				full_args = [GitHosting::git_exec(), '--git-dir', repo_path]
				if self.class.client_version_above?([1, 7, 2])
					full_args << '-c' << 'core.quotepath=false'
					full_args << '-c' << 'log.decorate=no'
				end
				full_args += args
				
				cmd_str=full_args.map { |e| shell_quote e.to_s }.join(' ')
				out=nil
				cached=GitCache.find_by_command(cmd_str)
				%x[ echo 'cmd_str = #{cmd_str}' > /tmp/cmd_str.txt ]
				if cached != nil
					cur_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
					if cur_time.to_i - cached.created_at.to_i < cache_time && cache_time >= 0
						out = cached.output
						%x[ echo '#{cached.output}' > /tmp/output.txt ]
					else
						GitCache.destroy(cached.id)
					end
				end
				if out == nil
					shellout(cmd_str) do |io|
						out = io.read
					end
					if $? && $?.exitstatus != 0
						raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "git exited with non-zero status: #{$?.exitstatus}"
					else
						%x[ echo '#{out}' > /tmp/out.txt ]
						GitCache.create( :command=>cmd_str, :output=>out.to_s )
						if GitCache.count > max_cache && max_cache >= 0
							oldest = GitCache.find(:last, :order => "created_on DESC")
							GitCache.destroy(oldest.id)
						end
					end
				end
				sio = StringIO.new(string=out)
				if block_given?
					block.call(sio)
				end
				sio
			end


		end
	end
end
Redmine::Scm::Adapters::GitAdapter.send(:include, GitHosting::Patches::GitAdapterPatch) unless Redmine::Scm::Adapters::GitAdapter.include?(GitHosting::Patches::GitAdapterPatch)
