require_dependency 'repositories_helper'

module GitHosting
	module Patches
		module RepositoriesHelperPatch
			def git_field_tags_with_hosting_configuration(form, repository)
				content = ''

				gd = 1
				gh = 1
				nc = 0

				if repository
					gd = repository[:git_daemon] ? repository[:git_daemon] : gd
					gh = repository[:git_http] ? repository[:git_http] : gh
					nc = repository[:notify_cia] ? repository[:notify_cia] : nc
				end
				gd = @project.is_public ? gd : 0

				GitHosting.logger.debug "Git Daemon for project \"#{@project.identifier}\": #{gd}"
				GitHosting.logger.debug "Git HTTP for project \"#{@project.identifier}\": #{gh}"
				GitHosting.logger.debug "Git Notify CIA for project \"#{@project.identifier}\": #{nc}"

				git_daemon_options = ''
				[l(:label_disabled), l(:label_enabled)].each_with_index{|label, index|
					if not @project.is_public and index==1
						next  # we could also break since it's the last index
					end
					if gd==index
						git_daemon_options << content_tag('option', label, :value => index, :selected => "selected")
					else
						git_daemon_options << content_tag('option', label, :value => index)
					end
				}
				git_daemon_select = ''
				git_daemon_select << content_tag("label", l(:label_git_daemon), :for => 'git_daemon')
				git_daemon_select << content_tag("select", "\n#{git_daemon_options}\n", :id => 'repository_git_daemon', :name => 'repository[git_daemon]')
				content << content_tag("p", "\n#{git_daemon_select}\n")

				git_http_options = ''
				[l(:label_disabled), l(:label_https_only), l(:label_https_and_http)].each_with_index{|label, index|
					if gh==index
						git_http_options << content_tag('option', label, :value => index, :selected => "selected")
					else
						git_http_options << content_tag('option', label, :value => index)
					end
				}
				git_http_select = ''
				git_http_select << content_tag("label", l(:label_git_http), :for => 'git_http')
				git_http_select << content_tag("select", "\n#{git_http_options}\n", :id => 'repository_git_http', :name => 'repository[git_http]')
				content << content_tag("p", "\n#{git_http_select}\n")


				notify_cia_options = ''
				[l(:label_disabled), l(:label_enabled)].each_with_index{|label, index|
					if nc==index
						notify_cia_options << content_tag('option', label, :value => index, :selected => "selected")
					else
						notify_cia_options << content_tag('option', label, :value => index)
					end
				}

				notify_cia_select = ''
				notify_cia_select << content_tag("label", l(:label_notify_cia), :for => 'notify_cia')
				notify_cia_select << content_tag("select", "\n#{notify_cia_options}\n", :id => 'repository_notify_cia', :name => 'repository[notify_cia]')
				if nc == 1
					notify_cia_test_url = url_for(:controller => "gitolite_hooks", :action => "test", :project_id => @project.identifier)
					notify_cia_test = content_tag("a", l(:label_notify_cia_test), :href => notify_cia_test_url, :id => 'notify_cia_test')
					notify_cia_result = content_tag("b", "<em><span id='notify_cia_result'></span></em>")
					notify_cia_select << "\n&nbsp;#{notify_cia_test}&nbsp;#{notify_cia_result}"
					notify_cia_select << "\n#{javascript_include_tag('notify_cia_test', :plugin => 'redmine_git_hosting')}"
				end
				content << content_tag("p", "\n#{notify_cia_select}\n")
				#GitHosting.logger.debug "Generated HTML:\n #{content}"
				return content

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
