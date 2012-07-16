class GitoliteHooksController < ApplicationController

	skip_before_filter :verify_authenticity_token, :check_if_login_required, :except => :test
	before_filter  :find_project

	helper :git_hosting
	include GitHostingHelper


	def stub
		# Stub method simply to generate correct urls, just return a 404 to any user requesting this
		render(:code => 404)
	end

	# Returns an array of GitHub post-receive hook style hashes
	# http://help.github.com/post-receive-hooks/
	def post_receive_payloads(refs, project=nil)
		project ||= @project
		payloads = []
		refs.each do |ref|
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

			revisions_in_range = %x[#{GitHosting.git_exec} --git-dir='#{GitHosting.repository_path(project)}' rev-list --reverse #{range}]
			#GitHosting.logger.debug "Revisions in Range: #{revisions.split().join(' ')}"

			commits = []
			revisions_in_range.split().each do |rev|
				revision = project.repository.find_changeset_by_name(rev.strip)
				commit = {
					:id => revision.revision,
					:url => url_for(:controller => "repositories", :action => "revision", 
						:id => project, :rev => rev, :only_path => false, 
						:host => Setting['host_name'], :protocol => Setting['protocol']
					),
					:author => {
						:name => revision.committer.gsub(/^([^<]+)\s+.*$/, '\1'),
						:email => revision.committer.gsub(/^.*<([^>]+)>.*$/, '\1')
					},
					:message => revision.comments,
					:timestamp => revision.committed_on,
					:added => [],
					:modified => [],
					:removed => []
				}
				revision.changes.each do |change|
					if change.action == "M"
						commit[:modified] << change.path
					elsif change.action == "A"
						commit[:added] << change.path
					elsif change.action == "D"
						commit[:removed] << change.path
					end
				end
				commits << commit
			end

			payloads << {
				:before => oldhead,
				:after => newhead,
				:ref => refname,
				:commits => commits,
				:repository => {
					:description => project.description,
					:fork => false,
					:forks => 0,
					:homepage => project.homepage,
					:name => project.identifier,
					:open_issues => project.issues.open.length,
					:owner => {
						:name => Setting["app_title"],
						:email => Setting["mail_from"]
					},
					:private => !project.is_public,
					:url => url_for(:controller => "repositories", :action => "show", 
						:id => project, :only_path => false, 
						:host => Setting["host_name"], :protocol => Setting["protocol"]
					),
					:watchers => 0
				}
			}
		end
		payloads
	end

	def post_receive

		if not @project.repository.extra.validate_encoded_time(params[:clear_time], params[:encoded_time])
			render(:text => "The hook key provided is not valid. Please let your server admin know about it")
			return
		end

		# Clear existing cache
		GitHosting::clear_cache_for_project(@project)

		repo_path = GitHosting.repository_path(@project)

		render :text => Proc.new { |response, output|
			response.headers["Content-Type"] = "text/plain;"

			# Fetch commits from the repository
			GitHosting.logger.debug "Fetching changesets for #{@project.name}'s repository"
			output.write("Fetching changesets for #{@project.name}'s repository ... ")
			output.flush
			Repository.fetch_changesets_for_project(@project.identifier)
			output.write("Done\n")
			output.flush

			payloads = []
			if @project.repository_mirrors.has_explicit_refspec.any? or @project.repository.extra.notify_cia == 1 or @project.repository_post_receive_urls.any? 
				payloads = post_receive_payloads(params[:refs])
			end

			@project.repository_mirrors.all(:order => 'active DESC, created_at ASC', :conditions => "active=1").each {|mirror|
              			if mirror.needs_push payloads
                                	GitHosting.logger.debug "Pushing changes to #{mirror.url} ... "
					output.write("Pushing changes to mirror #{mirror.url} ... ")
					output.flush

					(mirror_err,mirror_message) = mirror.push

					result = mirror_err ? "Failed!\n" + mirror_message : "Done\n"
					output.write(result)
					output.flush
                                end
			} if @project.repository_mirrors.any?

			# Post to each post-receive URL
            		@project.repository_post_receive_urls.all(:order => "active DESC, created_at ASC", :conditions => "active=1").each {|prurl|
				msg = "Posting #{payloads.length} post-receive payloads to #{prurl.url} ... "
				GitHosting.logger.debug msg
				output.write msg
				output.flush
				uri = URI(prurl.url)
              			payloads.each {|payload|
					if prurl.mode == :github
						res = Net::HTTP.post_form(uri, {"payload" => payload.to_json})
					else
						res = Net::HTTP.get_response(uri)
					end
					output.write res.is_a?(Net::HTTPSuccess) ? "[success] " : "[failure] "
					output.flush
              			}
				output.write "done\n"
				output.flush
            		} if @project.repository_post_receive_urls.any?

			# Notify CIA
			#Thread.abort_on_exception = true
			Thread.new(@project, payloads) {|project, payloads|
				GitHosting.logger.debug "Notifying CIA"
				output.write("Notifying CIA\n")
				output.flush

				payloads.each do |payload|
					branch = payload[:ref].gsub("refs/heads/", "")
					payload[:commits].each do |commit|
						revision = project.repository.find_changeset_by_name(commit["id"])
						next if project.repository.cia_notifications.notified?(revision)  # Already notified about this commit
						GitHosting.logger.info "Notifying CIA: Branch => #{branch} REVISION => #{revision.revision}"
						CiaNotificationMailer.deliver_notification(revision, branch)
						project.repository.cia_notifications.notified(revision)
					end
				end

			} if !params[:refs].nil? && @project.repository.extra.notify_cia==1
		}, :layout => false
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
		branch = %x[#{GitHosting.git_exec} --git-dir='#{repo_path}' branch --contains  #{revision.scmid}].split('\n')[0].strip.gsub(/\* /, '')
		GitHosting.logger.debug "Revision #{revision.scmid} found on branch #{branch}"

		# Send the test notification
		GitHosting.logger.info "Sending Test Notification to CIA: Branch => #{branch} RANGE => #{revision.revision}"
		CiaNotificationMailer.deliver_notification(revision, branch)
		render(:text => l(:cia_notification_ok))
	end

	def find_project
		@project = Project.find_by_identifier(params[:projectid])
		if @project.nil?
			render(:text => l(:project_not_found, :identifier => params[:projectid])) if @project.nil?
			return
		end
	end

end
