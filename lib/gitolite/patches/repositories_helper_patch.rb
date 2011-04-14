require_dependency 'repositories_helper'
module Gitolite
	module Patches
		module RepositoriesHelperPatch
			def git_field_tags_with_hosting_configuration(form, repository)
				
				left_style="style='display:block;float:left;width:150px;margin-right:5px'"
				right_style="style='display:block;margin-left:210px;'"
				git_daemon_label = "Git Daemon"
				git_http_pull_label = "Git Smart HTTP (pull)"
				git_http_push_label = "Git Smart HTTP (push)"
				enabled_label = "Enabled"
				disabled_label = "Disabled"
				https_only_label = "HTTPS Only"
				https_and_http_label = "HTTPS and HTTP"

				git_daemon_pull_options = "<option value='0'>#{disabled_label}</option>" + (@project.is_public ? "<option value='1'>#{enabled_label}</option>" : "") 
				git_http_options = "<option value='2'>#{https_and_http_label}</option><option value='1'>#{https_only_label}</option><option value='0'>#{disabled_label}</option>"
				
				git_daemon_pull_control = "<label #{left_style} for='git_daemon_pull'>#{git_daemon_label}:</label><select id='git_daemon_pull' #{right_style}>" + git_daemon_pull_options + "</select>";
				git_http_pull_control = "<label #{left_style} for='git_http_pull'>#{git_http_pull_label}:</label><select id='git_http_pull' #{right_style}>" + git_http_options + "</select>";
				git_http_push_control = "<label #{left_style} for='git_http_pull'>#{git_http_push_label}:</label><select id='git_http_pull' #{right_style}>" + git_http_options + "</select>";

				return git_daemon_pull_control + git_http_pull_control + git_http_push_control	


			end
      
			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.send(:alias_method_chain, :git_field_tags, :hosting_configuration)
			end
		end
	end
end
RepositoriesHelper.send(:include, Gitolite::Patches::RepositoriesHelperPatch) unless RepositoriesHelper.include?(Gitolite::Patches::RepositoriesHelperPatch)
