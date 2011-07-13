require_dependency 'redmine/scm/adapters/git_adapter'
module GitHosting
	module Hooks
		module GitAdapterHooks

			def self.logger
				return RAILS_DEFAULT_LOGGER
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

			def self.check_hooks_installed
				post_receive_hook_path = File.join(gitolite_hooks_dir, 'post-receive')
				post_receive_exists = %x[#{GitHosting.git_user_runner} test -r '#{post_receive_hook_path}' && echo 'yes' || echo 'no']
				if post_receive_exists.match(/no/)
					logger.info "[RedmineGitHosting] \"post-receive.redmine_gitolite\" not handled by gitolite, installing it..."
					install_hook("post-receive.redmine_gitolite")
					logger.info "[RedmineGitHosting] \"post-receive.redmine_gitolite\ installed"
					logger.info "[RedmineGitHosting] Running \"gl-setup\" on the gitolite install..."
					%x[#{GitHosting.git_user_runner} gl-setup]
					logger.info "[RedmineGitHosting] Finished installing hooks in the gitolite install..."
				else
					logger.info "[RedmineGitHosting] \"post-receive.redmine_gitolite\" hook exists!"
				end
			end

			def self.install_hook(hook_name)
				hook_source_path = File.join(package_hooks_dir, hook_name)
				hook_dest_path = File.join(gitolite_hooks_dir, hook_name.split('.')[0])
				logger.info "[RedmineGitHosting] Installing \"#{hook_name}\" from #{hook_source_path}"
				git_user = Setting.plugin_redmine_git_hosting['gitUser']
				if git_user == GitHosting.web_user
					%x[#{GitHosting.git_user_runner} 'cp #{hook_source_path} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'chown #{git_user}:#{git_user} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'chmod 700 #{hook_dest_path}']
				else
					# TODO: Need to test this with diferent users
					%x[#{GitHosting.git_user_runner} 'sudo -u #{web_user} cp #{hook_source_path} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'sudo -u #{web_user} chown #{git_user}:#{git_user} #{hook_dest_path}']
					%x[#{GitHosting.git_user_runner} 'sudo -u #{web_user} chmod 700 #{hook_dest_path}']
				end
			end

			def self.setup_hooks_for_project(project)
				logger.info "[RedmineGitHosting] Setting up hooks for project #{project.identifier}"
				debug_hook = Setting.plugin_redmine_git_hosting['gitDebugPostUpdateHook']
				curl_ignore_security = Setting.plugin_redmine_git_hosting['gitPostUpdateHookCurlIgnore']
				repo_path = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], GitHosting.repository_name(project))
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.key #{Setting['sys_api_key']}]
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.server #{Setting['host_name']}]
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config hooks.redmine_gitolite.projectid #{project.identifier}]
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config --bool hooks.redmine_gitolite.debug #{debug_hook}]
				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' config --bool hooks.redmine_gitolite.curlignoresecurity #{curl_ignore_security}]
			end

			def self.setup_hooks(projects=nil)
				# TODO: Need to find out how to call this when this plugin's settings are saved
				check_hooks_installed()
				if projects.nil?
					projects = Project.visible.find(:all).select{|p| p.repository.is_a?(Repository::Git)}
				end
				projects.each do |project|
					setup_hooks_for_project(project)
				end
			end
		end
	end
end
