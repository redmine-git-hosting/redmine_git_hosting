module Faker
  class Git < Base
    flexible :git

    class << self

      def http_url
        "http://#{domain_name}/#{base_path}"
      end


      def https_url
        "https://#{domain_name}/#{base_path}"
      end


      def ssh_url(port = 22)
        "ssh://git@#{domain_name}:#{port}/#{base_path}"
      end


      def git_url
        "git@#{domain_name}:#{base_path}"
      end


      private


        def domain_name
          "www.#{Internet.domain_name}"
        end


        def base_path
          "#{project_identifier}/#{project_identifier}/#{project_identifier}.git"
        end


        def project_identifier
          Internet.user_name(nil, ['-', '_'])
        end

    end

  end
end
