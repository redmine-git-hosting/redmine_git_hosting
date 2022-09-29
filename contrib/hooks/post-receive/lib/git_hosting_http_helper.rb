# frozen_string_literal: true

require 'json'
require 'net/http'
require 'net/https'
require 'uri'

module GitHosting
  module HttpHelper
    def http_post(url, opts = {}, &block)
      http, request = build_post_request url, **opts
      send_http_request http, request, &block
    end

    private

    def build_post_request(url, **opts)
      # Get params
      params = opts.delete(:params) { {} }

      # Build request
      uri, http = build_http_request url, **opts
      request = Net::HTTP::Post.new uri.request_uri

      # Set request
      request.body = URI.encode_www_form params
      request.content_type = 'application/x-www-form-urlencoded'

      [http, request]
    end

    def build_http_request(url, open_timeout: 5, read_timeout: 10)
      uri  = URI url
      http = Net::HTTP.new uri.host, uri.port
      if uri.scheme == 'https'
        http.use_ssl = true
        # @NOTE: do not allow requests with invalid certificates
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # Set HTTP options
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      [uri, http]
    end

    def send_http_request(http, request)
      if block_given?
        yield http, request
      else
        one_shot_request http, request
      end
    end

    def one_shot_request(http, request)
      message = +''
      begin
        res = http.start { |openhttp| openhttp.request request }
        if res.is_a? Net::HTTPSuccess
          message = res.body
          failed = false
        else
          message = "Return code : #{res.code} (#{res.message})."
          failed = true
        end
      rescue StandardError => e
        message = "Exception : #{e.message}"
        failed = true
      end

      [failed, message]
    end
  end
end
