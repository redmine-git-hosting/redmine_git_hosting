module GitHosting
  class PostReceive

    include HttpHelper

    attr_reader :repo_path
    attr_reader :refs
    attr_reader :git_config


    def initialize(repo_path, refs)
      @repo_path  = repo_path
      @refs       = refs
      @git_config = Config.new
    end


    def exec
      notify_redmine if git_config.valid?
    end


    private


      def notify_redmine
        logger.info('')
        logger.info("Notifying Redmine about changes to this repository : '#{git_config.repository_name}' ...")

        http_post(git_config.project_url, { params: http_post_data }) do |http, request|
          begin
            http.request(request) { |response| check_response(response) }
          rescue => e
            logger.error("HTTP_ERROR : #{e.message}")
          end
        end

        logger.info('')
      end


      def http_post_data
        git_config.post_data.merge('refs[]' => parsed_refs)
      end


      def parsed_refs
        parsed = []
        refs.split("\n").each do |line|
          r = line.chomp.strip.split
          parsed << [r[0].to_s, r[1].to_s, r[2].to_s].join(',')
        end
        parsed
      end


      def check_response(response)
        if response.code.to_i == 200
          response.read_body do |body_frag|
            body_frag.split("\n").each { |line| logger.info(line) }
          end
        else
          logger.error("  - Error while notifying Redmine ! (status code: #{response.code})")
        end
      end


      def logger
        @logger ||= GitHosting::HookLogger.new(loglevel: git_config.loglevel)
      end

  end
end
