require 'net/http'
require 'net/https'
require 'uri'

module Hooks
  module HttpHelper
    unloadable

    def post_data(url, payload, opts={})
      uri  = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      if opts[:method] == :post
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({"payload" => payload.to_json})
      else
        request = Net::HTTP::Get.new(uri.request_uri)
      end

      message = ""

      begin
        res = http.start {|openhttp| openhttp.request request}
        if !res.is_a?(Net::HTTPSuccess)
          message = "Return code : #{res.code} (#{res.message})."
          failed = true
        else
          message = res.body
          failed = false
        end
      rescue => e
        message = "Exception : #{e.message}"
        failed = true
      end

      return failed, message
    end

  end
end
