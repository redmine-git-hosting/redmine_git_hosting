require 'json'
require 'net/http'
require 'net/https'
require 'uri'

module RedmineGitHosting
  module Utils
    module Http
      extend self

      def http_post(url, opts = {})
        data = opts.delete(:data) { {} }
        data = serialize_data data
        http, request = build_post_request url, data
        send_http_request http, request
      end

      def http_get(url, _opts = {})
        http, request = build_get_request url
        send_http_request http, request
      end

      def valid_url?(url)
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP)
      rescue URI::InvalidURIError
        false
      end

      private

      def serialize_data(data)
        return data if data.empty?

        serialized = {}
        data.each do |k, v|
          serialized[k.to_s] = v.to_json
        end
        serialized
      end

      def build_post_request(url, data)
        uri, http = build_http_request url
        request = Net::HTTP::Post.new uri.request_uri
        request.basic_auth(uri.user, uri.password) if uri.user.present? && uri.password.present?
        request.set_form_data data
        [http, request]
      end

      def build_get_request(url)
        uri, http = build_http_request url
        request = Net::HTTP::Get.new uri.request_uri
        [http, request]
      end

      def build_http_request(url)
        uri  = URI url
        http = Net::HTTP.new uri.host, uri.port
        if uri.scheme == 'https'
          http.use_ssl = true
          # @NOTE: do not allow requests with invalid certificates
          # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        [uri, http]
      end

      def send_http_request(http, request)
        message = ''

        begin
          res = http.start { |openhttp| openhttp.request request }
          if !res.is_a?(Net::HTTPSuccess)
            message = "Return code : #{res.code} (#{res.message})."
            failed = true
          else
            message = res.body
            failed = false
          end
        rescue StandardError => e
          message = "Exception : #{e.message}"
          failed = true
        end

        [failed, message]
      end
    end
  end
end
