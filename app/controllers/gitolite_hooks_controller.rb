
class GitoliteHooksController < ApplicationController

	skip_before_filter :verify_authenticity_token, :check_if_login_required

	helper :cia_commits
	include CiaCommitsHelper

	def post_receive

		api_key = params[:key]

		if not api_key
			# If there's no key param, for sure it's not our hook
			GitHosting.logger.warn "No API key was passed"
			render(:status => 403, :text => 'Required API Key not present')
			return
		end

		if api_key != GitHookKey.get
			# If there's a key but it does not match, it's a misconfiguration issue
			GitHosting.logger.warn "The passed API key is not valid"
			render(:status => 403, :text => 'The used API Key is not valid!')
			return
		end

		project = Project.find_by_identifier(params[:project_id])
		if project.nil?
			render(:text => "No project found with identifier '#{params[:project_id]}'") if project.nil?
			return
		end

		# Clear existing cache
		old_cached=GitCache.find_all_by_proj_identifier(project.identifier)
		if old_cached != nil
			GitHosting.logger.debug "Clearing git cache for project #{project.name}"
			old_ids = old_cached.collect(&:id)
			GitCache.destroy(old_ids)
		end

		# Fetch commits from the repository
		GitHosting.logger.debug "Fetching changesets for #{project.name}'s repository"
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
