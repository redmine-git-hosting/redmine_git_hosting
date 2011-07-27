require_dependency 'repositories_helper'
module GitHosting
	module Patches
		module RepositoriesHelperPatch
			def git_field_tags_with_hosting_configuration(form, repository)
				gd = 1
				gh = 1
				nc = 0
				if repository
					gd = repository[:git_daemon] ? repository[:git_daemon] : gd
					gh = repository[:git_http] ? repository[:git_http] : gh
					nc = repository[:notify_cia] ? repository[:notify_cia] : nc
				end
				gd = @project.is_public ? gd : 0

				gdd = gd == 0 ? " selected='selected' " : ""
				gde = gd == 1 ? " selected='selected' " : ""
				git_daemon_options = "<option #{gdd} value='0'>#{l(:label_disabled)}</option>" + (@project.is_public ? "<option #{gde} value='1'>#{l(:label_enabled)}</option>" : "")


				git_http_options = ""
				hoption=0
				name_order = [ l(:label_disabled), l(:label_https_only), l(:label_https_and_http) ]
				while hoption <= 2
					selected = gh == hoption ? " selected='selected' " : ""
					git_http_options = git_http_options + "<option value='#{hoption}' #{selected}>#{ name_order[hoption] }</option>"
					hoption = hoption +1
				end

				ncd = nc == 0 ? " selected='selected' " : ""
				nce = nc == 1 ? " selected='selected' " : ""
				notify_cia_options = "<option #{ncd} value='0'>#{l(:label_disabled)}</option><option #{nce} value='1'>#{l(:label_enabled)}</option>"

				git_daemon_control = "<label for='git_daemon'>#{l(:label_git_daemon)}:</label><select id='repository_git_daemon' name='repository[git_daemon]'>" + git_daemon_options + "</select>";
				git_http_control = "<label for='git_http'>#{l(:label_git_http)}:</label><select id='repository_git_http' name='repository[git_http]'>" + git_http_options + "</select>";
				notify_cia_control = "<label for='notify_cia'>#{l(:label_notify_cia)}:</label><select id='repository_notify_cia' name='repository[notify_cia]'>" + notify_cia_options + "</select>";

				return "\n<p>" + git_daemon_control + "</p>\n<p>" +  git_http_control + "</p>\n<p>" +  notify_cia_control + "</p>\n"


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
