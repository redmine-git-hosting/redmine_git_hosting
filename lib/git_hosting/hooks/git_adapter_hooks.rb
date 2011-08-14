require 'digest/md5'
require_dependency 'redmine/scm/adapters/git_adapter'

module GitHosting
	module Hooks
		module GitAdapterHooks

			@@python_hook_digest = nil
			@@installed_hook_digest = nil

			@@check_hooks_installed_stamp = nil
			@@check_hooks_installed_cached = nil
			def self.check_hooks_installed
				if not @@check_hooks_installed_cached.nil? and (Time.new - @@check_hooks_installed_stamp <= 0.5):
					return @@check_hooks_installed_cached
				end

				create_hooks_digests

				post_receive_hook_path = File.join(gitolite_hooks_dir, 'post-receive')
				post_receive_exists = %x[#{GitHosting.git_user_runner} test -r '#{post_receive_hook_path}' && echo 'yes' || echo 'no']
				if post_receive_exists.match(/no/)
					logger.info "\"post-receive\" not handled by gitolite, installing it..."
					if python_available == true
						logger.info "python is available, installing faster version of hook"
						install_hook("post-receive.redmine_gitolite.py")
					else
						install_hook("post-receive.redmine_gitolite")
					end
					logger.info "\"post-receive.redmine_gitolite\ installed"
					logger.info "Running \"gl-setup\" on the gitolite install..."
					%x[#{GitHosting.git_user_runner} gl-setup]
					logger.info "Finished installing hooks in the gitolite install..."
					@@check_hooks_installed_stamp = Time.new
					@@check_hooks_installed_cached = true
					return @@check_hooks_installed_cached
				else
					git_user = Setting.plugin_redmine_git_hosting['gitUser']
					web_user = GitHosting.web_user
					if git_user == web_user
						digest = Digest::MD5.file(File.expand_path(post_receive_hook_path))
					else
						contents = %x[#{GitHosting.git_user_runner} 'cat #{post_receive_hook_path}']
						digest = Digest::MD5.hexdigest(contents)
					end

					logger.debug "Installed hook digest: #{digest}"
					@@installed_hook_digest = digest
					if @@hook_digests.include? digest
						logger.info "Our hook is already installed"
						@@check_hooks_installed_stamp = Time.new
						@@check_hooks_installed_cached = true
						return @@check_hooks_installed_cached
					else
						error_msg = "\"post-receive\" is alreay present but it's not ours!"
						logger.warn error_msg
						@@check_hooks_installed_stamp = Time.new
						@@check_hooks_installed_cached = error_msg
						return @@check_hooks_installed_cached
					end
				end
			end

			def self.install_hook(hook_name)
				hook_source_path = File.join(package_hooks_dir, hook_name)
				hook_dest_path = File.join(gitolite_hooks_dir, hook_name.split('.')[0])
				logger.info "Installing \"#{hook_name}\" from #{hook_source_path} to #{hook_dest_path}"
				git_user = Setting.plugin_redmine_git_hosting['gitUser']
				web_user = GitHosting.web_user
				if git_user == web_user
					%x[#{GitHosting.git_user_runner} 'cp #{hook_source_path} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'chown #{git_user}:#{git_user} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'chmod 700 #{hook_dest_path}']
				else
					%x[#{GitHosting.git_user_runner} 'sudo -nu #{web_user} cat #{hook_source_path} | cat - >  #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'chown #{git_user}:#{git_user} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'chmod 700 #{hook_dest_path}']
				end
				create_hooks_digests(true)
			end

			def self.setup_hooks_for_project(project)
				logger.info "Setting up hooks for project #{project.identifier}"

				if project.repository.nil?
					logger.info "Repository for project #{project.identifier} is not yet created"
					return
				end

				repo_path = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], GitHosting.repository_name(project))
				logger.debug "Repository Path: #{repo_path}"

				hook_key = project.repository.extra.encode_key
				logger.debug "Hook KEY: #{hook_key}"
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.key "#{hook_key}"]

				hook_url = Setting.plugin_redmine_git_hosting['gitHooksUrl']
				logger.debug "Hook URL: #{hook_url}"
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.url "#{hook_url}"]

				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.projectid "#{project.identifier}"]

				debug_hook = Setting.plugin_redmine_git_hosting['gitHooksDebug']
				logger.debug "Debug Hook: #{debug_hook}"
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config --bool hooks.redmine_gitolite.debug "#{debug_hook}"]

				curl_ignore_security = Setting.plugin_redmine_git_hosting['gitHooksCurlIgnore']
				logger.debug "Hook Ignore Curl Security: #{curl_ignore_security}"
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config --bool hooks.redmine_gitolite.curlignoresecurity "#{curl_ignore_security}"]
			end

			def self.setup_hooks(projects=nil)
				# TODO: Need to find out how to call this when this plugin's settings are saved
				check_hooks_installed()
				if projects.nil?
					projects = Project.visible.find(:all).select{|p| p.repository.is_a?(Repository::Git)}
				elsif projects.instance_of? Project
					projects = [projects]
				end
				projects.each do |project|
					setup_hooks_for_project(project)
				end
			end

			def self.python_hook_installed?
				if !@@installed_hook_digest.nil? && !@@python_hook_digest.nil?
					return (@@installed_hook_digest == @@python_hook_digest)
				end
				return false
			end

			private

			def self.logger
				return GitHosting::logger
			end

			@@package_hooks_dir = nil

			def self.gitolite_hooks_dir
				return '~/.gitolite/hooks/common'
			end

			def self.package_hooks_dir
				if @@package_hooks_dir.nil?
					@@package_hooks_dir = File.join(File.dirname(File.dirname(File.dirname(File.dirname(__FILE__)))), 'contrib', 'hooks')
				end
				return @@package_hooks_dir
			end

			@python_available = nil
			def self.python_available
				if @python_available.nil?
					python_test = %x[#{GitHosting.git_user_runner} "which python 2>/dev/null && echo 'yes_we_have_python' || echo 'no'"].chomp.strip
					logger.info "Python test result #{python_test}"
					@python_available = python_test.match(/yes_we_have_python/)? true : false
				end
				@python_available
			end

			@@hook_digests = []
			def self.create_hooks_digests(recreate=false)
				if recreate == true
					@@hook_digests = []
				end
				if @@hook_digests.empty?
					logger.info "Creating MD5 digests for our hooks"
					["post-receive.redmine_gitolite", "post-receive.redmine_gitolite.py"].each do |hook_name|
						digest = Digest::MD5.file(File.join(package_hooks_dir, hook_name))
						logger.info "Digest for #{hook_name}: #{digest}"
						@@hook_digests.push(digest)
						if hook_name == "post-receive.redmine_gitolite.py"
							@@python_hook_digest = digest
						end
					end
				end
			end

		end
	end
end
