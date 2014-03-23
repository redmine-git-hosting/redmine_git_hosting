class GitoliteHooksController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token, :check_if_login_required
  before_filter      :find_project_and_repository
  before_filter      :validate_hook_key

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


  private


  def logger
    RedmineGitolite::Log.get_logger(:git_hooks)
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
