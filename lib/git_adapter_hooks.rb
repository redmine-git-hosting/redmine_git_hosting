require 'digest/md5'
require_dependency 'redmine/scm/adapters/git_adapter'

module GitHosting
	class GitAdapterHooks

		@@check_hooks_installed_stamp = nil
		@@check_hooks_installed_cached = nil

		def self.check_hooks_installed
			if not @@check_hooks_installed_cached.nil? and (Time.new - @@check_hooks_installed_stamp <= 0.5):
				return @@check_hooks_installed_cached
			end

			post_receive_hook_path = File.join(gitolite_hooks_dir, 'post-receive')
			post_receive_exists = (%x[#{GitHosting.git_user_runner} test -r '#{post_receive_hook_path}' && echo 'yes' || echo 'no']).match(/yes/)
			post_receive_length_is_zero = false
			if post_receive_exists
				post_receive_length_is_zero= "0" == (%x[echo 'wc -c  #{post_receive_hook_path}' | #{GitHosting.git_user_runner} "bash" ]).chomp.strip.split(/[\t ]+/)[0]
			end

			if (!post_receive_exists) || post_receive_length_is_zero
				logger.info "\"post-receive\" not handled by gitolite, installing it..."
				install_hook("post-receive.redmine_gitolite.rb")
				logger.info "\"post-receive.redmine_gitolite\ installed"
				logger.info "Running \"gl-setup\" on the gitolite install..."
				%x[#{GitHosting.git_user_runner} gl-setup]
				update_global_hook_params
				logger.info "Finished installing hooks in the gitolite install..."
				@@check_hooks_installed_stamp = Time.new
				@@check_hooks_installed_cached = true
				return @@check_hooks_installed_cached
			else
				contents = %x[#{GitHosting.git_user_runner} 'cat #{post_receive_hook_path}']
				digest = Digest::MD5.hexdigest(contents)

				logger.debug "Installed hook digest: #{digest}"
				if rgh_hook_digest == digest
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


		def self.setup_hooks(projects=nil)
			check_hooks_installed
			update_global_hook_params

			if projects.nil?
				projects = Project.visible.find(:all).select{|p| p.repository.is_a?(Repository::Git)}
			elsif projects.instance_of? Project
				projects = [projects]
			end
			projects.each do |project|
				setup_hooks_for_project(project)
			end
		end

		def self.update_global_hook_params
			hook_url = "http://" + Setting.plugin_redmine_git_hosting['httpServer'] + "/githooks/post-receive"
			logger.debug "Hook URL: #{hook_url}"
			%x[#{GitHosting.git_exec} config --global hooks.redmine_gitolite.url "#{hook_url}"]

			debug_hook = Setting.plugin_redmine_git_hosting['gitHooksDebug']
			logger.debug "Debug Hook: #{debug_hook}"
			%x[#{GitHosting.git_exec} config --global --bool hooks.redmine_gitolite.debug "#{debug_hook}"]

			asynch_hook = Setting.plugin_redmine_git_hosting['gitHooksAreAsynchronous']
			logger.debug "Hooks Are Asynchronous: #{asynch_hook}"
			%x[#{GitHosting.git_exec} config --global --bool hooks.redmine_gitolite.asynch "#{asynch_hook}"]


		end


		private

		def self.logger
			return GitHosting::logger
		end


		def self.gitolite_hooks_dir
			return '~/.gitolite/hooks/common'
		end

		@@cached_hooks_dir = nil
		def self.package_hooks_dir
			ret = @@cached_hooks_dir.nil? ? File.join(File.dirname(File.dirname(__FILE__)), 'contrib', 'hooks') : @@cached_hooks_dir
			ret
		end

		@@cached_hook_digest = nil
		def self.rgh_hook_digest(recreate=false)
			if @@cached_hook_digest.nil? || recreate
				logger.info "Creating MD5 digests for Redmine Git Hosting hook"
				hook_file = "post-receive.redmine_gitolite.rb"
				digest = Digest::MD5.hexdigest(File.read(File.join(package_hooks_dir, hook_file)))
				logger.info "Digest for #{hook_file}: #{digest}"
				@@cached_hook_digest = digest
			end
			@@cached_hook_digest
		end
		def self.install_hook(hook_name)
			hook_source_path = File.join(package_hooks_dir, hook_name)
			hook_dest_path = File.join(gitolite_hooks_dir, hook_name.split('.')[0])
			logger.info "Installing \"#{hook_name}\" from #{hook_source_path} to #{hook_dest_path}"
			git_user = Setting.plugin_redmine_git_hosting['gitUser']
			%x[ cat #{hook_source_path} |  #{GitHosting.git_user_runner} 'cat - > #{hook_dest_path}']
			%x[#{GitHosting.git_user_runner} 'chown #{git_user} #{hook_dest_path}']
			%x[#{GitHosting.git_user_runner} 'chmod 700 #{hook_dest_path}']

		end


		def self.setup_hooks_for_project(project)
			logger.info "Setting up hooks for project #{project.identifier}"
			if project.repository.nil?
				logger.info "Repository for project #{project.identifier} is not yet created"
				return
			end

			repo_path = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], GitHosting.repository_name(project))
			hook_key = project.repository.extra.key
			%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.key "#{hook_key}"]
			%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.projectid "#{project.identifier}"]
		end

	end
end
