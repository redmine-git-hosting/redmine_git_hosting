module RedmineHooks
  class Webservices < Base
    unloadable

    include HttpHelper

    attr_reader :payloads_to_send


    def initialize(*args)
      super

      @payloads_to_send = []
      set_payloads_to_send
    end


    def call
      call_webservice if needs_push?
    end


    def post_receive_url
      object
    end


    private


      def needs_push?
        return false if payloads.empty?
        return true unless use_triggers?
        return false if post_receive_url.triggers.empty?
        return !payloads_to_send.empty?
      end


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
        post_receive_url.mode == :github ? :http_post : :http_get
      end


      def use_triggers?
        post_receive_url.use_triggers?
      end


      def split_payloads?
        post_receive_url.split_payloads?
      end


      def call_webservice
        if use_method == :http_post && split_payloads?
          payloads_to_send.each do |payload|
            do_call_webservice(payload)
          end
        else
          do_call_webservice(payloads_to_send)
        end
      end


      def do_call_webservice(payload)
        y = ''

        logger.info("Notifying #{post_receive_url.url} ... ")
        y << "  - Notifying #{post_receive_url.url} ... "

        post_failed, post_message = self.send(use_method, post_receive_url.url, { data: { payload: payload } })

        if post_failed
          logger.error('Failed!')
          logger.error("#{post_message}")
          y << " [failure]\n"
        else
          logger.info('Succeeded!')
          y << " [success]\n"
        end

        y
      end

  end
end
