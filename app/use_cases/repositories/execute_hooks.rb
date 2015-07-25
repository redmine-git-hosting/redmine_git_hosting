module Repositories
  class ExecuteHooks
    unloadable

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
      self.send("call_#{hook_type}_hooks")
    end


    private


      def logger
        RedmineGitHosting.logger
      end


      def call_redmine_hooks
        Hooks::Redmine.call(repository)
      end


      def call_git_mirrors_hooks
        y = ''

        ## Post to each post-receive URL
        if repository.mirrors.active.any?
          logger.info('Notifying mirrors about changes to this repository :')
          y << "\nNotifying mirrors about changes to this repository :\n"

          repository.mirrors.active.each do |mirror|
            y << Hooks::GitMirrors.call(mirror, payloads)
          end
        end

        y
      end


      def call_web_services_hooks
        y = ''

        ## Post to each post-receive URL
        if repository.post_receive_urls.active.any?
          logger.info('Notifying post receive urls about changes to this repository :')
          y << "\nNotifying post receive urls about changes to this repository :\n"

          repository.post_receive_urls.active.each do |post_receive_url|
            y << Hooks::Webservices.call(post_receive_url, payloads)
          end
        end

        y
      end

  end
end
