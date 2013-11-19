include ActionView::Helpers::TextHelper

class GitoliteHooksController < ApplicationController

  skip_before_filter :verify_authenticity_token, :check_if_login_required, :except => :notify_cia_test
  before_filter  :find_project_and_repository

  helper :git_hosting
  include GitHostingHelper


  def stub
    # Stub method simply to generate correct urls, just return a 404 to any user requesting this
    render(:code => 404)
  end


  def get_enumerator
    if RUBY_VERSION == '1.8.7'
      Enumerable::Enumerator
    else
      Enumerator
    end
  end


  def post_receive
    if not @repository.extra.validate_encoded_time(params[:clear_time], params[:encoded_time])
      render(:text => "The hook key provided is not valid. Please let your server admin know about it")
      return
    end

    ## Clear existing cache
    GitHostingCache.clear_cache_for_repository(@repository)

    if Rails::VERSION::MAJOR >= 3
      self.response.headers["Content-Type"] = "text/plain;"

      self.response_body = get_enumerator.new do |y|
        # Fetch commits from the repository
        logger.info "Fetching changesets for '#{@project.identifier}' repository"
        y << "Fetching changesets for '#{@project.identifier}' repository ... "
        begin
          @repository.fetch_changesets
        rescue Redmine::Scm::Adapters::CommandFailed => e
          logger.error "Error during fetching changesets: #{e.message}"
        end
        y << "Done\n"

        payloads = []
        if @repository.repository_mirrors.has_explicit_refspec.any? or @repository.extra.notify_cia == 1 or @repository.repository_post_receive_urls.any?
          payloads = post_receive_payloads(params[:refs])
        end

        @repository.repository_mirrors.all(:order => 'active DESC, created_at ASC', :conditions => "active=1").each {|mirror|
          if mirror.needs_push payloads
            logger.info "Pushing changes to '#{mirror.url}' ... "
            y << "Pushing changes to mirror '#{mirror.url}' ... "

            (mirror_err,mirror_message) = mirror.push

            result = mirror_err ? "Failed!\n" + mirror_message : "Done\n"
            y << result
          end
        } if @repository.repository_mirrors.any?

        # Post to each post-receive URL
        @repository.repository_post_receive_urls.all(:order => "active DESC, created_at ASC", :conditions => "active=1").each {|prurl|
          if prurl.mode == :github
            msg = "Sending #{pluralize(payloads.length,'notification')} to #{prurl.url} ... "
          else
            msg = "Notifying #{prurl.url} ... "
          end
          y << msg

          uri = URI(prurl.url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')

          errmsg = nil
          payloads.each {|payload|
            begin
              if prurl.mode == :github
                request = Net::HTTP::Post.new(uri.request_uri)
                request.set_form_data({"payload" => payload.to_json})
              else
                request = Net::HTTP::Get.new(uri.request_uri)
              end
              res = http.start {|openhttp| openhttp.request request}
              errmsg = "Return code: #{res.code} (#{res.message})." if !res.is_a?(Net::HTTPSuccess)
            rescue => e
              errmsg = "Exception: #{e.message}"
            end
            break if errmsg || prurl.mode != :github
          }

          if errmsg
            y << "[failure] done\n"
            logger.error "#{msg}Failed!\n  #{errmsg}"
          else
            y << "[success] done\n"
            logger.info "#{msg}Succeeded!"
          end
        } if @repository.repository_post_receive_urls.any?

        # Notify CIA
        #Thread.abort_on_exception = true
        Thread.new(@repository, payloads) {|repository, payloads|
          logger.info "Notifying CIA"
          y << "Notifying CIA\n"

          payloads.each do |payload|
            branch = payload[:ref].gsub("refs/heads/", "")
            payload[:commits].each do |commit|
              revision = repository.find_changeset_by_name(commit["id"])
              next if repository.cia_notifications.notified?(revision)  # Already notified about this commit
              GitHosting.logger.info "Notifying CIA: Branch => #{branch} REVISION => #{revision.revision}"
              CiaNotificationMailer.deliver_notification(revision, branch)
              repository.cia_notifications.notified(revision)
            end
          end

        } if !params[:refs].nil? && @repository.extra.notify_cia == 1

      end
    else
      render :text => Proc.new { |response, output|
        response.headers["Content-Type"] = "text/plain;"

        # Fetch commits from the repository
        logger.info "Fetching changesets for #{@project.name}'s repository"
        output.write("Fetching changesets for #{@project.name}'s repository ... ")
        output.flush
        begin
          @repository.fetch_changesets
        rescue Redmine::Scm::Adapters::CommandFailed => e
          logger.error "Error during fetching changesets: #{e.message}"
        end
        output.write("Done\n")
        output.flush

        payloads = []
        if @repository.repository_mirrors.has_explicit_refspec.any? or @repository.extra.notify_cia == 1 or @repository.repository_post_receive_urls.any?
          payloads = post_receive_payloads(params[:refs])
        end

        @repository.repository_mirrors.all(:order => 'active DESC, created_at ASC', :conditions => "active=1").each {|mirror|
          if mirror.needs_push payloads
            logger.info "Pushing changes to '#{mirror.url}' ... "
            output.write("Pushing changes to mirror '#{mirror.url}' ... ")
            output.flush

            (mirror_err,mirror_message) = mirror.push

            result = mirror_err ? "Failed!\n" + mirror_message : "Done\n"
            output.write(result)
            output.flush
          end
        } if @repository.repository_mirrors.any?

        # Post to each post-receive URL
        @repository.repository_post_receive_urls.all(:order => "active DESC, created_at ASC", :conditions => "active=1").each {|prurl|
          if prurl.mode == :github
            msg = "Sending #{pluralize(payloads.length,'notification')} to #{prurl.url} ... "
          else
            msg = "Notifying #{prurl.url} ... "
          end
          output.write msg
          output.flush

          uri = URI(prurl.url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')

          errmsg = nil
          payloads.each {|payload|
            begin
              if prurl.mode == :github
                request = Net::HTTP::Post.new(uri.request_uri)
                request.set_form_data({"payload" => payload.to_json})
              else
                request = Net::HTTP::Get.new(uri.request_uri)
              end
              res = http.start {|openhttp| openhttp.request request}
              errmsg = "Return code: #{res.code} (#{res.message})." if !res.is_a?(Net::HTTPSuccess)
            rescue => e
              errmsg = "Exception: #{e.message}"
            end
            break if errmsg || prurl.mode != :github
          }

          if errmsg
            output.write "[failure] done\n"
            logger.error "#{msg}Failed!\n  #{errmsg}"
          else
            output.write "[success] done\n"
            logger.info "#{msg}Succeeded!s"
          end
          output.flush
        } if @repository.repository_post_receive_urls.any?

        # Notify CIA
        #Thread.abort_on_exception = true
        Thread.new(@repository, payloads) {|repository, payloads|
          logger.info "Notifying CIA"
          output.write("Notifying CIA\n")
          output.flush

          payloads.each do |payload|
            branch = payload[:ref].gsub("refs/heads/", "")
            payload[:commits].each do |commit|
              revision = repository.find_changeset_by_name(commit["id"])
              next if repository.cia_notifications.notified?(revision)  # Already notified about this commit
              logger.info "Notifying CIA: Branch => #{branch} REVISION => #{revision.revision}"
              CiaNotificationMailer.deliver_notification(revision, branch)
              repository.cia_notifications.notified(revision)
            end
          end

        } if !params[:refs].nil? && @repository.extra.notify_cia == 1

      }, :layout => false
    end
  end

  def notify_cia_test
    # Deny access if the current user is not allowed to manage the project's repositoy
    not_enough_perms = true
    User.current.roles_for_project(@project).each{|role|
      if role.allowed_to? :manage_repository
        not_enough_perms = false
        break
      end
    }

    not_enough_perms = false if User.current.admin?
    return render(:text => l(:cia_not_enough_permissions), :status => 403) if not_enough_perms

    # Grab the repository path
    repo_path = GitHosting.repository_path(@repository)

    # Get the last revision we have on the database for this project
    revision = @repository.changesets.find(:first)

    if !revision.nil?
      # Find out to which branch this commit belongs to
      branch = %x[#{GitHosting.git_cmd_runner} --git-dir='#{repo_path}' branch --contains  #{revision.scmid}].split('\n')[0].strip.gsub(/\* /, '')
      logger.info "Revision #{revision.scmid} found on branch #{branch}"

      # Send the test notification
      logger.info "Sending Test Notification to CIA: Branch => #{branch} RANGE => #{revision.revision}"
      CiaNotificationMailer.deliver_notification(revision, branch)
      return render(:text => l(:text_cia_notification_ok))
    else
      return render(:text => l(:text_cia_notification_nok))
    end
  end

  protected

  @@logger = nil
  def logger
    @@logger ||= GitoliteLogger.get_logger(:git_hooks)
  end

  # Returns an array of GitHub post-receive hook style hashes
  # http://help.github.com/post-receive-hooks/
  def post_receive_payloads(refs)
    payloads = []
    refs.each do |ref|
      oldhead, newhead, refname = ref.split(',')

      # Only pay attention to branch updates
      next if not refname.match(/refs\/heads\//)
      branch = refname.gsub('refs/heads/', '')

      if newhead.match(/^0{40}$/)
        # Deleting a branch
        logger.info "Deleting branch \"#{branch}\""
        next
      elsif oldhead.match(/^0{40}$/)
        # Creating a branch
        logger.info "Creating branch \"#{branch}\""
        range = newhead
      else
        range = "#{oldhead}..#{newhead}"
      end

      # Grab the repository path
      repo_path = GitHosting.repository_path(@repository)
      revisions_in_range = %x[#{GitHosting.git_cmd_runner} --git-dir='#{repo_path}' rev-list --reverse #{range}]
      logger.info "Revisions in Range: #{revisions_in_range.split().join(' ')}"

      commits = []
      revisions_in_range.split().each do |rev|
        revision = @repository.find_changeset_by_name(rev.strip)
        commit = {
          :id => revision.revision,
          :url => url_for(:controller => "repositories", :action => "revision",
                          :id => @project, :rev => rev, :only_path => false,
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
          :description => @project.description,
          :fork => false,
          :forks => 0,
          :homepage => @project.homepage,
          :name => @project.identifier,
          :open_issues => @project.issues.open.length,
          :owner => {
            :name => Setting["app_title"],
            :email => Setting["mail_from"]
          },
          :private => !@project.is_public,
          :url => url_for(:controller => "repositories", :action => "show",
                          :id => @project, :only_path => false,
                          :host => Setting["host_name"], :protocol => Setting["protocol"]
                  ),
          :watchers => 0
        }
      }
    end
    payloads
  end


  # Locate that actual repository that is in use here.
  # Notice that an empty "repositoryid" is assumed to refer to the default repo for a project
  def find_project_and_repository
    @project = Project.find_by_identifier(params[:projectid])
    if @project.nil?
      render :text => l(:error_project_not_found, :identifier => params[:projectid]) if @project.nil?
      return
    end

    if GitHosting.multi_repos?
      if params[:repositoryid] && !params[:repositoryid].blank?
        @repository = @project.repositories.find_by_identifier(params[:repositoryid])
      else
        # return default or first repo with blank identifier
        @repository = @project.repository || @project.repo_blank_ident
      end
    else
      # Only repository if redmine < 1.4
      @repository = @project.repository
    end

    if @repository.nil?
      render_404
    end
  end

end
