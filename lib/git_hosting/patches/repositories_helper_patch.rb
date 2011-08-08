require_dependency 'repositories_helper'
require_dependency 'git_hosting_helper'

module GitHosting
	module Patches

		module RepositoriesHelperPatch

			def git_field_tags_with_hosting_configuration(form, repository)
				@controller.send(
					:render_to_string,
					:partial => 'repositories/repositories_helper.erb',
					:locals => { :form => form, :repository => repository }
				)
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
