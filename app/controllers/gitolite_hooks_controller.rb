
class GitoliteHooksController < ApplicationController

	skip_before_filter :verify_authenticity_token, :check_if_login_required, :except => :test
	before_filter  :find_project

	helper :git_hosting
	include GitHostingHelper

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

		# Clear existing cache
		old_cached=GitCache.find_all_by_proj_identifier(@project.identifier)
		if old_cached != nil
			GitHosting.logger.debug "Clearing git cache for project #{@project.name}"
			old_ids = old_cached.collect(&:id)
			GitCache.destroy(old_ids)
		end

		# Fetch commits from the repository
		GitHosting.logger.debug "Fetching changesets for #{@project.name}'s repository"
		Repository.fetch_changesets_for_project(@project.identifier)

		# Notify CIA
		Thread.new(@project, params[:refs]) {|project, refs|
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
		} if not params[:refs].nil? and @project.repository.notify_cia==1

		render(:text => 'OK')
	end

	def test
		# Deny access if the curreent user is not allowed to manage the project's repositoy
		not_enough_perms = true
		User.current.roles_for_project(@project).each{|role|
			if role.allowed_to? :manage_repository
				not_enough_perms = false
				break
			end
		}
		return render(:text => l(:cia_not_enough_permissions), :status => 403) if not_enough_perms

		# Grab the repository path
		repo_path = GitHosting.repository_path(@project)
		# Get the last revision we have on the database for this project
		revision = @project.repository.changesets.find(:first)
		# Find out to which branch this commit belongs to
		branch = %x[#{GitHosting.git_exec} --git-dir='#{repo_path}.git' branch --contains  #{revision.scmid}].split('\n')[0].strip

		# Send the test notification
		GitHosting.logger.info "Sending Test Notification to CIA: Branch => #{branch} RANGE => #{revision.revision}"
		CiaNotificationMailer.deliver_notification(revision, branch)
		render(:text => l(:cia_notification_ok))
	end

	def find_project
		@project = Project.find_by_identifier(params[:project_id])
		if @project.nil?
			render(:text => l(:project_not_found, :identifier => params[:project_id])) if @project.nil?
			return
		end
	end
end
