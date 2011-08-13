
class GitoliteHooksController < ApplicationController

	def stub
		# Stub method simply to generate correct urls, just return a 404 to any user requesting this
		render(:code => 404)
	end

	def post_receive

		project = Project.find_by_identifier(params[:project_id])
		if project.nil?
			render(:text => "No project found with identifier '#{params[:project_id]}'")
			return
		end

		if project.repository.extra.check_key(params[:key]) == false
			render(:text => "The hook key provided is not valid. Please let your server admin know about it")
			return
		end

		# Clear cache
		old_cached=GitCache.find_all_by_proj_identifier(project.identifier)
		if old_cached != nil
			old_ids = old_cached.collect(&:id)
			GitCache.destroy(old_ids)
		end

		Repository.fetch_changesets_for_project(project.identifier)
		render(:text => 'OK')
	end
end
