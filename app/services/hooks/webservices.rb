module Hooks
  class Webservices
    unloadable

    include HttpHelper

    attr_reader :post_receive_url
    attr_reader :payloads
    attr_reader :url
    attr_reader :payloads_to_send


    def initialize(post_receive_url, payloads)
      @post_receive_url = post_receive_url
      @payloads         = payloads
      @url              = post_receive_url.url
      @payloads_to_send = []

      set_payloads_to_send
    end


    class << self

      def logger
        RedmineGitHosting.logger
      end


      def execute(repository, payloads)
        y = ''

        ## Post to each post-receive URL
        if repository.post_receive_urls.active.any?
          logger.info("Notifying post receive urls about changes to this repository :")
          y << "\nNotifying post receive urls about changes to this repository :\n"

          repository.post_receive_urls.active.each do |post_receive_url|
            y << self.new(post_receive_url, payloads).execute
          end
        end

        y
      end

    end


    def execute
      call_webservice if needs_push?
    end


    def needs_push?
      return false if payloads.empty?
      return true unless use_triggers?
      return false if post_receive_url.triggers.empty?
      return !payloads_to_send.empty?
    end


    private


      def set_payloads_to_send
        if use_triggers?
          @payloads_to_send = extract_payloads
        else
          @payloads_to_send = payloads
        end
      end


      def extract_payloads
        new_payloads = []
        payloads.each do |payload|
          data = RedmineGitHosting::Utils.refcomp_parse(payload[:ref])
          if data[:type] == 'heads' && post_receive_url.triggers.include?(data[:name])
            new_payloads << payload
          end
        end
        new_payloads
      end


      def use_method
        post_receive_url.mode == :github ? :post : :get
      end


      def use_triggers?
        post_receive_url.use_triggers?
      end


      def split_payloads?
        post_receive_url.split_payloads?
      end


       do_call_webservice
        if use_method == :post && split_payloads?
          payloads_to_send.each do |payload|
            do_call_webservice(payload)
          end
        else
          do_call_webservice(payloads_to_send)
        end
      end


      def do_call_webservice(payload)
        y = ''

        logger.info("Notifying #{url} ... ")
        y << "  - Notifying #{url} ... "

        post_failed, post_message = post_data(url, payload, method: use_method)

        if post_failed
          logger.error("Failed!")
          logger.error("#{post_message}")
          y << " [failure]\n"
        else
          logger.info("Succeeded!")
          y << " [success]\n"
        end

        y
      end


      def logger
        RedmineGitHosting.logger
      end

  end
end
