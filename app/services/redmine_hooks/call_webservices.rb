module RedmineHooks
  class CallWebservices < Base
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


    def needs_push?
      return false if payloads.empty?
      return true unless use_triggers?
      return false if post_receive_url.triggers.empty?
      return !payloads_to_send.empty?
    end


    def start_message
      "Notifying #{post_receive_url.url}"
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
        post_receive_url.mode == :github ? :http_post : :http_get
      end


      def use_triggers?
        post_receive_url.use_triggers?
      end


      def split_payloads?
        post_receive_url.split_payloads?
      end


      def call_webservice
        execute_hook do |y|
          if use_method == :http_post && split_payloads?
            payloads_to_send.each do |payload|
              do_call_webservice(y, payload)
            end
          else
            do_call_webservice(y, payloads_to_send)
          end
        end
      end


      def do_call_webservice(y, payload)
        post_failed, post_message = self.send(use_method, post_receive_url.url, { data: { payload: payload } })

        unless post_failed
          log_hook_succeeded
          y << (split_payloads? ? success_message.gsub("\n", '') : success_message)
        else
          logger.error('Failed!')
          logger.error(post_message)
          y << (split_payloads? ? failure_message.gsub("\n", '') : failure_message)
        end
      end

  end
end
