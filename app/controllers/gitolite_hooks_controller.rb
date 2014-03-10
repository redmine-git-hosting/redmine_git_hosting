require 'net/http'
require 'net/https'
require 'uri'

include ActionView::Helpers::TextHelper

class GitoliteHooksController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token, :check_if_login_required
  before_filter      :find_project_and_repository


  def stub
    # Stub method simply to generate correct urls, just return a 404 to any user requesting this
    render(:code => 404)
  end


  def post_receive
    if !@repository.extra.validate_encoded_time(params[:clear_time], params[:encoded_time])
      render(:text => "The hook key provided is not valid. Please let your server admin know about it")
      return
    end

    ## Clear existing cache
    RedmineGitolite::Cache.clear_cache_for_repository(@repository)

    self.response.headers["Content-Type"] = "text/plain;"

    self.response_body = Enumerator.new do |y|

      ## Fetch commits from the repository
      logger.info { "Fetching changesets for '#{@project.identifier}' repository ... " }
      y << "  - Fetching changesets for '#{@project.identifier}' repository ... "

      begin
        @repository.fetch_changesets
        logger.info { "Succeeded!" }
        y << " [success]\n"
      rescue Redmine::Scm::Adapters::CommandFailed => e
        logger.error { "Failed!" }
        logger.error { "Error during fetching changesets: #{e.message}" }
        y << " [failure]\n"
      end

      payloads = []

      if @repository.repository_mirrors.has_explicit_refspec.any? || @repository.repository_post_receive_urls.any?
        payloads = post_receive_payloads(params[:refs])
      end

      ## Push to each mirror
      @repository.repository_mirrors.all(:order => 'active DESC, created_at ASC', :conditions => "active=1").each do |mirror|
        if mirror.needs_push(payloads)
          logger.info { "Pushing changes to #{mirror.url} ... " }
          y << "  - Pushing changes to #{mirror.url} ... "

          push_failed, push_message = mirror.push

          if push_failed
            logger.error { "Failed!" }
            logger.error { "#{push_message}" }
            y << " [failure]\n"
          else
            logger.info { "Succeeded!" }
            y << " [success]\n"
          end
        end
      end if @repository.repository_mirrors.any?


      ## Post to each post-receive URL
      @repository.repository_post_receive_urls.all(:order => "active DESC, created_at ASC", :conditions => "active=1").each do |prurl|
        if prurl.mode == :github
          message = "  - Sending #{pluralize(payloads.length, 'notification')} to #{prurl.url} ... "
        else
          message = "  - Notifying #{prurl.url} ... "
        end

        y << message

        uri  = URI(prurl.url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        error_message = nil

        payloads.each do |payload|
          begin
            if prurl.mode == :github
              request = Net::HTTP::Post.new(uri.request_uri)
              request.set_form_data({"payload" => payload.to_json})
            else
              request = Net::HTTP::Get.new(uri.request_uri)
            end

            res = http.start {|openhttp| openhttp.request request}
            error_message = "Return code: #{res.code} (#{res.message})." if !res.is_a?(Net::HTTPSuccess)
          rescue => e
            error_message = "Exception: #{e.message}"
          end

          break if error_message || prurl.mode != :github
        end

        if error_message
          logger.error { "#{message} Failed!" }
          logger.error { "#{error_message}" }
          y << " [failure]\n"
        else
          logger.info { "#{message} Succeeded!" }
          y << " [success]\n"

        end
      end if @repository.repository_post_receive_urls.any?

    end
  end


  protected


  def logger
    RedmineGitolite::Log.get_logger(:git_hooks)
  end


  # Returns an array of GitHub post-receive hook style hashes
  # http://help.github.com/post-receive-hooks/
  def post_receive_payloads(refs)
    payloads = []

    refs.each do |ref|

      oldhead, newhead, refname = ref.split(',')

      # Only pay attention to branch updates
      next if !refname.match(/refs\/heads\//)

      branch = refname.gsub('refs/heads/', '')

      if newhead.match(/^0{40}$/)
        # Deleting a branch
        logger.info { "Deleting branch '#{branch}'" }
        next
      elsif oldhead.match(/^0{40}$/)
        # Creating a branch
        logger.info { "Creating branch '#{branch}'" }
        range = newhead
      else
        range = "#{oldhead}..#{newhead}"
      end

      # Grab the repository path
      revisions_in_range = RedmineGitolite::GitHosting.execute_command(:git_cmd, "--git-dir='#{@repository.gitolite_repository_path}' rev-list --reverse #{range}")
      logger.debug { "Revisions in range : #{revisions_in_range.split().join(' ')}" }

      commits = []

      revisions_in_range.split().each do |rev|
        logger.debug { "Revision : '#{rev.strip}'" }
        revision = @repository.find_changeset_by_name(rev.strip)
        next if revision.nil?

        commit = {
          :id        => revision.revision,
          :message   => revision.comments,
          :timestamp => revision.committed_on,
          :added     => [],
          :modified  => [],
          :removed   => [],
          :author    => {
            :name  => revision.committer.gsub(/^([^<]+)\s+.*$/, '\1'),
            :email => revision.committer.gsub(/^.*<([^>]+)>.*$/, '\1')
          },
          :url => url_for(:controller => "repositories", :action => "revision",
                          :id => @project, :rev => rev, :only_path => false,
                          :host => Setting['host_name'], :protocol => Setting['protocol'])
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
        :before     => oldhead,
        :after      => newhead,
        :ref        => refname,
        :commits    => commits,
        :repository => {
          :description => @project.description,
          :fork        => false,
          :forks       => 0,
          :homepage    => @project.homepage,
          :name        => @project.identifier,
          :open_issues => @project.issues.open.length,
          :watchers    => 0,
          :private     => !@project.is_public,
          :owner       => {
            :name  => Setting["app_title"],
            :email => Setting["mail_from"]
          },
          :url => url_for(:controller => "repositories", :action => "show",
                          :id => @project, :only_path => false,
                          :host => Setting["host_name"], :protocol => Setting["protocol"])
        }
      }
    end

    return payloads
  end


  # Locate that actual repository that is in use here.
  # Notice that an empty "repositoryid" is assumed to refer to the default repo for a project
  def find_project_and_repository
    @project = Project.find_by_identifier(params[:projectid])
    if @project.nil?
      render :text => l(:error_project_not_found, :identifier => params[:projectid]) if @project.nil?
      return
    end

    if params[:repositoryid] && !params[:repositoryid].blank?
      @repository = @project.repositories.find_by_identifier(params[:repositoryid])
    else
      # return default or first repo with blank identifier
      @repository = @project.repository || @project.repo_blank_ident
    end

    if @repository.nil?
      render_404
    end
  end

end
