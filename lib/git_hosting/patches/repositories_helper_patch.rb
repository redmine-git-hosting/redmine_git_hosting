require_dependency 'repositories_helper'
module GitHosting
	module Patches
		module RepositoriesHelperPatch
			def git_field_tags_with_hosting_configuration(form, repository)
				git_daemon_label = "Git Daemon"
				git_http_label = "Git Smart HTTP"
				enabled_label = "Enabled"
				disabled_label = "Disabled"
				https_only_label = "HTTPS Only"
				https_and_http_label = "HTTPS and HTTP"

				gd = 1
				gh = 1
				if repository
					gd = repository[:git_daemon] ? repository[:git_daemon] : gd
					gh = repository[:git_http] ? repository[:git_http] : gh
				end
				gd = @project.is_public ? gd : 0
				
				gdd = gd == 0 ? " selected='selected' " : ""
				gde = gd == 1 ? " selected='selected' " : ""
				git_daemon_options = "<option #{gdd} value='0'>#{disabled_label}</option>" + (@project.is_public ? "<option #{gde} value='1'>#{enabled_label}</option>" : "") 
				
				
				git_http_options = ""
				hoption=0
				name_order = [ disabled_label, https_only_label, https_and_http_label ]
				while hoption <= 2
					selected = gh == hoption ? " selected='selected' " : ""
					git_http_options = git_http_options + "<option value='#{hoption}' #{selected}>#{ name_order[hoption] }</option>"
					hoption = hoption +1
				end
				
				git_daemon_control = "<label for='git_daemon'>#{git_daemon_label}:</label><select id='repository_git_daemon' name='repository[git_daemon]'>" + git_daemon_options + "</select>";
				git_http_control = "<label for='git_http'>#{git_http_label}:</label><select id='repository_git_http' name='repository[git_http]'>" + git_http_options + "</select>";

				return "\n<p>" + git_daemon_control + "</p>\n<p>" +  git_http_control + "</p>\n"


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
RepositoriesHelper.send(:include, GitHosting::Patches::RepositoriesHelperPatch) unless RepositoriesHelper.include?(GitHosting::Patches::RepositoriesHelperPatch)
