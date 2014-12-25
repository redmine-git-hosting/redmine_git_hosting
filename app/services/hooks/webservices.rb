module Hooks
  class Webservices
    unloadable

    include HttpHelper
    include BranchParser

    attr_reader :post_receive_url
    attr_reader :payloads
    attr_reader :url


    def initialize(post_receive_url, payloads)
      @post_receive_url = post_receive_url
      @payloads         = payloads
      @url              = post_receive_url.url
    end


    class << self

      def logger
        RedmineGitolite::Log.get_logger(:git_hooks)
      end


      def execute(repository, payloads)
        y = ''

        ## Post to each post-receive URL
        if repository.post_receive_urls.active.any?
          logger.info { "Notifying post receive urls about changes to this repository :" }
          y << "\nNotifying post receive urls about changes to this repository :\n"

          repository.post_receive_urls.active.each do |post_receive_url|
            y << self.new(post_receive_url, payloads).execute
          end
        end

        y
      end

    end


    def execute
      call_webservice
    end


    private


      def call_webservice
        if needs_push?
          if use_method == :post && split_payloads?
            extract_payloads.each do |payload|
              do_call_webservice(payload)
            end
          else
            do_call_webservice(payloads)
          end
        end
      end


      def needs_push?
        return false if payloads.empty?
        return true if !post_receive_url.use_triggers
        return true if post_receive_url.triggers.empty?
        return extract_payloads.empty?
      end


      def use_method
        post_receive_url.mode == :github ? :post : :get
      end


      def split_payloads?
        post_receive_url.split_payloads?
      end


      def extract_payloads
        new_payloads = []
        payloads.each do |payload|
          data = refcomp_parse(payload[:ref])
          if data[:type] == 'heads' && post_receive_url.triggers.include?(data[:name])
            new_payloads << payload
          end
        end
        new_payloads
      end


      def do_call_webservice(payload)
        y = ''

        logger.info { "Notifying #{url} ... " }
        y << "  - Notifying #{url} ... "

        post_failed, post_message = post_data(url, payload, method: use_method)

        if post_failed
          logger.error { "Failed!" }
          logger.error { "#{post_message}" }
          y << " [failure]\n"
        else
          logger.info { "Succeeded!" }
          y << " [success]\n"
        end

        y
      end


      def logger
        RedmineGitolite::Log.get_logger(:git_hooks)
      end

  end
end
