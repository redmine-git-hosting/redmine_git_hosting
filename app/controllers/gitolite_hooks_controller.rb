require 'json'

class GitoliteHooksController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token, :check_if_login_required

  before_filter      :find_project_and_repository, :only => :post_receive
  before_filter      :validate_hook_key,           :only => :post_receive

  before_filter      :find_project, :only => :post_receive_issue

  helper :gitolite_hooks


  def post_receive
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
        logger.error { "Error during fetching changesets : #{e.message}" }
        y << " [failure]\n"
      end


      ## Get payload
      payload = view_context.build_payload(params[:refs])


      ## Push to each mirror
      @repository.repository_mirrors.active.order('created_at ASC').each do |mirror|
        if mirror.needs_push(payload)
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
      @repository.repository_post_receive_urls.active.order('created_at ASC').each do |post_receive_url|
        logger.info { "Notifying #{post_receive_url.url} ... " }
        y << "  - Notifying #{post_receive_url.url} ... "

        method = (post_receive_url.mode == :github) ? :post : :get

        post_failed, post_message = view_context.post_data(post_receive_url.url, payload, :method => method)

        if post_failed
          logger.error { "Failed!" }
          logger.error { "#{post_message}" }
          y << " [failure]\n"
        else
          logger.info { "Succeeded!" }
          y << " [success]\n"
        end
      end if @repository.repository_post_receive_urls.any?

    end
  end


  def post_receive_issue
    github_issue = GithubIssue.find_by_github_id(params[:issue][:id])

    if github_issue.nil?
      redmine_issue = create_redmine_issue(params)
      github_issue = GithubIssue.new
      github_issue.github_id = params[:issue][:id]
      github_issue.issue_id = redmine_issue.id
      github_issue.save!
    end

    if params[:issue][:comments] > 0
      issue_journal = GithubComment.find_by_github_id(params[:comment][:id])

      if issue_journal.nil?
        issue_journal = create_issue_journal(params, github_issue.issue)

        github_comment = GithubComment.new
        github_comment.github_id = params[:comment][:id]
        github_comment.journal_id = issue_journal.id
        github_comment.save!
      end
    end

    render :text => "OK!"
    return
  end


  private


  def create_issue_journal(params, issue)
    journal = Journal.new
    journal.journalized_id = issue.id
    journal.journalized_type = 'Issue'
    journal.notes = params[:comment][:body]
    journal.created_on = params[:comment][:created_at]

    ## Get user mail
    user = find_user(params[:comment][:user][:url])
    journal.user_id = user.id

    journal.save!
    return journal
  end


  def create_redmine_issue(params)
    issue = Issue.new
    issue.project_id = @project.id
    issue.tracker_id = 2
    issue.subject = params[:issue][:title]
    issue.description = params[:issue][:body]
    issue.updated_on = params[:issue][:updated_at]
    issue.created_on = params[:issue][:created_at]

    ## Get user mail
    user = find_user(params[:issue][:user][:url])
    issue.author = user

    issue.save!
    return issue
  end


  def find_user(url)
    post_failed, user_data = view_context.post_data(url, "", :method => :get)
    user_data = JSON.parse(user_data)

    user = User.find_by_mail(user_data[:email])

    if user.nil?
      user = User.anonymous
    end

    return user
  end


  def logger
    RedmineGitolite::Log.get_logger(:git_hooks)
  end


  def find_project
    @project = Project.find_by_identifier(params[:project_id])

    if @project.nil?
      render :partial => 'gitolite_hooks/project_not_found'
      return
    end
  end


  # Locate that actual repository that is in use here.
  # Notice that an empty "repositoryid" is assumed to refer to the default repo for a project
  def find_project_and_repository
    @project = Project.find_by_identifier(params[:projectid])

    if @project.nil?
      render :partial => 'gitolite_hooks/project_not_found'
      return
    end

    if params[:repositoryid] && !params[:repositoryid].blank?
      @repository = @project.repositories.find_by_identifier(params[:repositoryid])
    else
      # return default or first repo with blank identifier
      @repository = @project.repository || @project.repo_blank_ident
    end

    if @repository.nil?
      render :partial => 'gitolite_hooks/repository_not_found'
    end
  end


  def validate_hook_key
    if !view_context.validate_encoded_time(params[:clear_time], params[:encoded_time], @repository.gitolite_hook_key)
      render :text => "The hook key provided is not valid. Please let your server admin know about it"
      return
    end
  end

end
