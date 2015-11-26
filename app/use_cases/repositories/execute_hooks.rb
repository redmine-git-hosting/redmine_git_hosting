module Repositories
  class ExecuteHooks

    attr_reader :repository
    attr_reader :hook_type
    attr_reader :payloads


    def initialize(repository, hook_type, payloads = {})
      @repository = repository
      @hook_type  = hook_type
      @payloads   = payloads
    end


    class << self

      def call(repository, hook_type, payloads = {})
        new(repository, hook_type, payloads).call
      end

    end


    def call
      self.send("execute_#{hook_type}_hook")
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def execute_fetch_changesets_hook
        RedmineHooks::FetchChangesets.call(repository)
      end


      def execute_update_mirrors_hook
        message = 'Notifying mirrors about changes to this repository :'
        y = ''

        ## Post to each post-receive URL
        if repository.mirrors.active.any?
          logger.info(message)
          y << "\n#{message}\n"

          repository.mirrors.active.each do |mirror|
            y << RedmineHooks::UpdateMirrors.call(mirror, payloads)
          end
        end

        y
      end


      def execute_call_webservices_hook
        message = 'Notifying post receive urls about changes to this repository :'
        y = ''

        ## Post to each post-receive URL
        if repository.post_receive_urls.active.any?
          logger.info(message)
          y << "\n#{message}\n"

          repository.post_receive_urls.active.each do |post_receive_url|
            y << RedmineHooks::CallWebservices.call(post_receive_url, payloads)
          end
        end

        y
      end

  end
end
