
class GitoliteHooksController < SysController

	def post_receive

		test_key=params[:key]
		if test_key == GitHosting.update_key
			project = Project.find_by_identifier(params[:project_id])
			if project.nil?
				render(:text => "No project found with identifier '#{params[:project_id]}'") if project.nil?
				return
			end

			# If for some reason we need to properly support the hook, we will also need to get
			# the refs that are beeing updated.
			#
			# For that, un-comment bellow.
			#
			#GitHosting.logger.info "Refs: #{params[:refs]}"
			#params[:refs].each {|ref|
			#	old, new, refname = ref.split(',')
			#	GitHosting.logger.info "Ref:  OLD=>#{old} NEW=>#{new} REFNAME=>#{refname}"
			#} if not params[:refs].nil?

			#clear cache
			old_cached=GitCache.find_all_by_proj_identifier(project.identifier)
			if old_cached != nil
				old_ids = old_cached.collect(&:id)
				GitCache.destroy(old_ids)
			end

			Repository.fetch_changesets_for_project(params[:project_id])
			render(:text => 'OK')
		end
	end
end
