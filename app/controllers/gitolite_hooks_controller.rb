class GitoliteHooksController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token, :check_if_login_required

  before_filter      :find_hook
  before_filter      :find_project
  before_filter      :find_repository
  before_filter      :validate_hook_key


  include GitoliteHooksHelper
  helper  :gitolite_hooks


  def post_receive
    method = "post_receive_#{@hook_type}"

    self.send(method)
  end


  private


  def post_receive_redmine
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
      payload = build_payload(params[:refs])


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
      @repository.repository_post_receive_urls.active.each do |post_receive_url|
        logger.info { "Notifying #{post_receive_url.url} ... " }
        y << "  - Notifying #{post_receive_url.url} ... "

        method = (post_receive_url.mode == :github) ? :post : :get

        post_failed, post_message = post_data(post_receive_url.url, payload, :method => method)

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


  def post_receive_github
    github_issue = GithubIssue.find_by_github_id(params[:issue][:id])
    redmine_issue = Issue.find_by_subject(params[:issue][:title])
    create_relation = false

    ## We don't have stored relation
    if github_issue.nil?

      ## And we don't have issue in Redmine
      if redmine_issue.nil?
        create_relation = true
        redmine_issue = create_redmine_issue(params)
      else
        ## Create relation and update issue
        create_relation = true
        redmine_issue = update_redmine_issue(redmine_issue, params)
      end
    else
      ## We have one relation, update issue
      redmine_issue = update_redmine_issue(github_issue.issue, params)
    end

    if create_relation
      github_issue = GithubIssue.new
      github_issue.github_id = params[:issue][:id]
      github_issue.issue_id = redmine_issue.id
      github_issue.save!
    end

    if params.has_key?(:comment)
      issue_journal = GithubComment.find_by_github_id(params[:comment][:id])

      if issue_journal.nil?
        issue_journal = create_issue_journal(github_issue.issue, params)

        github_comment = GithubComment.new
        github_comment.github_id = params[:comment][:id]
        github_comment.journal_id = issue_journal.id
        github_comment.save!
      end
    end

    render :text => "OK!"
    return
  end


  def logger
    RedmineGitolite::Log.get_logger(:git_hooks)
  end


  VALID_HOOKS = [ 'redmine', 'github' ]

  def find_hook
    if !VALID_HOOKS.include?(params[:type])
      render :text => "The hook name provided is not valid. Please let your server admin know about it"
      return
    else
      @hook_type = params[:type]
    end
  end


  def find_project
    @project = Project.find_by_identifier(params[:projectid])

    if @project.nil?
      render :partial => 'gitolite_hooks/project_not_found'
      return
    end
  end


  # Locate that actual repository that is in use here.
  # Notice that an empty "repositoryid" is assumed to refer to the default repo for a project
  def find_repository
    if @hook_type == 'redmine'
      if params[:repositoryid] && !params[:repositoryid].blank?
        @repository = @project.repositories.find_by_identifier(params[:repositoryid])
      else
        # return default or first repo with blank identifier
        @repository = @project.repository || @project.repo_blank_ident
      end

      if @repository.nil?
        render :partial => 'gitolite_hooks/repository_not_found'
        return
      end
    end
  end


  def validate_hook_key
    if @hook_type == 'redmine'
      if !validate_encoded_time(params[:clear_time], params[:encoded_time], @repository.gitolite_hook_key)
        render :text => "The hook key provided is not valid. Please let your server admin know about it"
        return
      end
    end
  end

end
