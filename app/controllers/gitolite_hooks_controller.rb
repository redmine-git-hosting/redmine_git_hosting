require 'digest/sha1'

class GitoliteHooksController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token, :check_if_login_required

  before_filter :find_hook
  before_filter :find_project
  before_filter :find_repository
  before_filter :validate_hook_key


  def post_receive
    method = "post_receive_#{@hook_type}"
    self.send(method)
  end


  private


    def post_receive_redmine
      # Clear existing cache
      RedmineGitHosting::CacheManager.clear_cache_for_repository(@repository)

      # Set response headers
      set_response_headers

      # Send body
      self.response_body = Enumerator.new do |y|
        # First fetch changesets
        y << Hooks::Redmine.new(@repository).execute

        # Then call hooks
        y << Hooks::GitMirrors.execute(@repository, payloads)
        y << Hooks::Webservices.execute(@repository, payloads)
      end
    end


    def set_response_headers
      self.response.headers['Content-Type']  = 'text/plain;'
      self.response.headers['Last-Modified'] = Time.now.to_s
      self.response.headers['Cache-Control'] = 'no-cache'
    end


    def payloads
      @payloads ||= GithubPayload.new(@repository, params[:refs]).build
    end


    def post_receive_github
      Hooks::GithubIssuesSync.new(@project, params).execute
      render text: 'OK!'
      return
    end


    VALID_HOOKS = [ 'redmine', 'github' ]

    def find_hook
      if !VALID_HOOKS.include?(params[:type])
        render text: 'The hook name provided is not valid. Please let your server admin know about it'
        return
      else
        @hook_type = params[:type]
      end
    end


    def find_project
      @project = Project.find_by_identifier(params[:projectid])

      if @project.nil?
        render partial: 'gitolite_hooks/project_not_found'
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
          render partial: 'gitolite_hooks/repository_not_found'
          return
        end
      end
    end


    def validate_hook_key
      if @hook_type == 'redmine'
        if !validate_encoded_time(params[:clear_time], params[:encoded_time], @repository.gitolite_hook_key)
          render text: 'The hook key provided is not valid. Please let your server admin know about it'
          return
        end
      end
    end


    def validate_encoded_time(clear_time, encoded_time, key)
      cur_time  = Time.new.utc.to_i
      test_time = clear_time.to_i

      valid = false

      if not_to_late?(cur_time, test_time)
        valid = true if encode_key(clear_time, key) == encoded_time.to_s
      end

      valid
    end


    def not_to_late?(cur_time, test_time)
      cur_time - test_time < 5*60
    end


    def encode_key(time, key)
      Digest::SHA1.hexdigest(time.to_s + key.to_s).to_s
    end

end
