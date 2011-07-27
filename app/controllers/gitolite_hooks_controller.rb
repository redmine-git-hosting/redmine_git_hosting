
class GitoliteHooksController < SysController

	helper :cia_commits
	include CiaCommitsHelper

	def post_receive
		project = Project.find_by_identifier(params[:project_id])
		if project.nil?
			render(:text => "No project found with identifier '#{params[:project_id]}'") if project.nil?
			return
		end

		# Clear existing cache
		old_cached=GitCache.find_all_by_proj_identifier(project.identifier)
		if old_cached != nil
			old_ids = old_cached.collect(&:id)
			GitCache.destroy(old_ids)
		end

		# Fetch commits from the repository
		Repository.fetch_changesets_for_project(params[:project_id])

		# Notify CIA
		params[:refs].each {|ref|
			oldhead, newhead, refname = ref.split(',')
			GitHosting.logger.info "Processing: REFNAME => #{refname} OLD => #{oldhead}  NEW => #{newhead}"
			repo_path = File.join(Setting.plugin_redmine_git_hosting['gitRepositoryBasePath'], GitHosting.repository_name(project))

			#revlist = %x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' rev-list #{oldhead}..#{newhead}]
			#GitHosting.logger.info "Revlist: #{revlist}"
			branch = refname.gsub('refs/heads/', '')
			%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' rev-list #{oldhead}..#{newhead}].reverse_each{|rev|
				revision = project.repository.find_changeset_by_name(rev.strip)
				if revision.notified_cia != 1
					GitHosting.logger.info "Notifying CIA: Branch => #{branch} REV => #{revision.revision}"
					CiaNotificationMailer.deliver_notification(revision, branch)
					# Bellow is to avoid notifing again when a merge is happening
					revision.notified_cia = 1
					revision.save
				end
			}
		} if not params[:refs].nil? and project.repository.notify_cia==1

		render(:text => 'OK')
	end
end
