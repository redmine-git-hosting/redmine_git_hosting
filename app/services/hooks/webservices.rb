module Hooks
  class Webservices
    unloadable

    include HttpHelper


    def initialize(repository, payload)
      @repository = repository
      @project    = repository.project
      @payload    = payload
    end


    def execute
      call_webservices
    end


    private


    def logger
      RedmineGitolite::Log.get_logger(:git_hooks)
    end


    def call_webservices
      y = ""

      ## Post to each post-receive URL
      if @repository.post_receive_urls.active.any?

        logger.info { "Notifying post receive urls about changes to this repository :" }
        y << "\nNotifying post receive urls about changes to this repository :\n"

        @repository.post_receive_urls.active.each do |post_receive_url|
          if payloads = post_receive_url.needs_push(@payload)

            method = (post_receive_url.mode == :github) ? :post : :get

            if method == :post && post_receive_url.split_payloads?
              payloads.each do |payload|
                logger.info { "Notifying #{post_receive_url.url} for '#{payload[:ref]}' ... " }
                y << "  - Notifying #{post_receive_url.url} for '#{payload[:ref]}' ... "

                post_failed, post_message = post_data(post_receive_url.url, payload, :method => method)

                if post_failed
                  logger.error { "Failed!" }
                  logger.error { "#{post_message}" }
                  y << " [failure]\n"
                else
                  logger.info { "Succeeded!" }
                  y << " [success]\n"
                end
              end
            else
              logger.info { "Notifying #{post_receive_url.url} ... " }
              y << "  - Notifying #{post_receive_url.url} ... "

              post_failed, post_message = post_data(post_receive_url.url, @payload, :method => method)

              if post_failed
                logger.error { "Failed!" }
                logger.error { "#{post_message}" }
                y << " [failure]\n"
              else
                logger.info { "Succeeded!" }
                y << " [success]\n"
              end
            end
          end
        end
      end

      return y
    end

  end
end
