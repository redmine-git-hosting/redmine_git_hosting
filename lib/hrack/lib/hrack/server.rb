# frozen_string_literal: true

require 'digest/sha1'

module Hrack
  class Server
    attr_reader :params

    PLAIN_TYPE = { 'Content-Type' => 'text/plain' }.freeze

    def initialize(config = {}); end

    def call(env)
      dup._call env
    end

    def _call(env)
      @env = env
      @req = Rack::Request.new env
      @params = @req.params.deep_symbolize_keys

      command, @project = match_routing

      return render_404 'Command Not Found' unless command
      return render_404 'Project Not Found' unless @project

      method(command).call
    end

    def post_receive_redmine
      @repository = find_repository
      return render_404 'Repository Not Found' if @repository.nil?
      unless valid_encoded_time? params[:clear_time], params[:encoded_time], @repository.gitolite_hook_key
        return render_403 'The hook key provided is not valid. Please let your server admin know about it'
      end

      @res = Rack::Response.new
      @res.status = 200
      @res['Content-Type'] = 'text/plain;'
      @res.finish do
        @res.write Repositories::ExecuteHooks.call(@repository, :fetch_changesets)
        @res.write Repositories::ExecuteHooks.call(@repository, :update_mirrors, payloads)
        @res.write Repositories::ExecuteHooks.call(@repository, :call_webservices, payloads)
      end
    end

    def post_receive_github
      Projects::ExecuteHooks.call @project, :github, **params
      render_200 'OK!'
    end

    private

    def payloads
      @payloads ||= Repositories::BuildPayload.call @repository, params[:refs]
    end

    def match_routing
      command = find_command
      project = find_project
      [command, project]
    end

    def find_command
      return unless path_parameters.key? :type

      case path_parameters[:type]
      when 'redmine'
        :post_receive_redmine
      when 'github'
        :post_receive_github
      end
    end

    def find_project
      Project.find_by identifier: path_parameters[:projectid] if path_parameters.key? :projectid
    end

    # Locate that actual repository that is in use here.
    # Notice that an empty "repositoryid" is assumed to refer to the default repo for a project
    def find_repository
      if params[:repositoryid].present?
        @project.repositories.find_by identifier: params[:repositoryid]
      else
        # return default or first repo with blank identifier
        @project.repository || @project.repo_blank_ident
      end
    end

    def render_200(message)
      [200, PLAIN_TYPE, [message]]
    end

    def render_404(message)
      [404, PLAIN_TYPE, [message]]
    end

    def render_403(message)
      [403, PLAIN_TYPE, [message]]
    end

    def path_parameters
      @env['action_dispatch.request.path_parameters']
    end

    def valid_encoded_time?(clear_time, encoded_time, key)
      cur_time  = Time.new.utc.to_i
      test_time = clear_time.to_i
      not_to_late?(cur_time, test_time) && encode_key(clear_time, key) == encoded_time.to_s
    end

    def not_to_late?(cur_time, test_time)
      cur_time - test_time < 5 * 60
    end

    def encode_key(time, key)
      Digest::SHA1.hexdigest(time.to_s + key.to_s).to_s
    end
  end
end
