
class GitoliteHooksController < ApplicationController

	skip_before_filter :verify_authenticity_token, :check_if_login_required, :except => :test

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
		Thread.new(project, params[:refs]) {|project, refs|
			repo_path = GitHosting.repository_path(project)
			refs.each {|ref|
				oldhead, newhead, refname = ref.split(',')

				# Only pay attention to branch updates
				next if not refname.match(/refs\/heads\//)

				branch = refname.gsub('refs/heads/', '')

				if newhead.match(/^0{40}$/)
					# Deleting a branch
					GitHosting.logger.debug "Deleting branch \"#{branch}\""
					next
				elsif oldhead.match(/^0{40}$/)
					# Creating a branch
					GitHosting.logger.debug "Creating branch \"#{branch}\""
					range = newhead
				else
					range = "#{oldhead}..#{newhead}"
				end

				%x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' rev-list --reverse #{range}].each{|rev|
					revision = project.repository.find_changeset_by_name(rev.strip)
					next if revision.notified_cia == 1   # Already notified about this commit
					GitHosting.logger.info "Notifying CIA: Branch => #{branch} RANGE => #{revision.revision}"
					CiaNotificationMailer.deliver_notification(revision, branch)
					revision.notified_cia = 1
					revision.save
				}
			}
		} if not params[:refs].nil? and project.repository.notify_cia==1

		render(:text => 'OK')
	end

	def test
		project = Project.find_by_identifier(params[:project_id])
		if project.nil?
			render(:text => "No project found with identifier '#{params[:project_id]}'") if project.nil?
			return
		end

		# Deny access if user is not a manager for this project
		manager_role = Role.find(:first, :conditions => ["name = ?", "Manager"])
		return render(
			:text => "Not enough permissions", :status => 403
		) if not User.current.roles_for_project(project).include? manager_role

		repo_path = GitHosting.repository_path(project)

		# Get the last revision we have on the database for this project
		revision = project.repository.changesets.find(:first)
		# Find out to which branch this commit belongs to
		branch = %x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' branch --contains  #{revision.scmid}].split('\n')[0].strip

		# Send the test notification
		GitHosting.logger.info "Sending Test Notification to CIA: Branch => #{branch} RANGE => #{revision.revision}"
		CiaNotificationMailer.deliver_notification(revision, branch)
		render(:text => 'CIA notification sent')
	end
end
