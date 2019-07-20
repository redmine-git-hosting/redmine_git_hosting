require 'digest/sha1'

module GitHosting
  class Config
    IGNORE_PARAMS = %w[redmineurl projectid debugmode asyncmode repositorykey].freeze
    REDMINE_PARAMS = %w[redminegitolite.redmineurl
                        redminegitolite.projectid
                        redminegitolite.repositoryid
                        redminegitolite.repositorykey
                        redminegitolite.debugmode
                        redminegitolite.asyncmode].freeze

    attr_reader :config

    def initialize
      @config = {}
      load_gitolite_vars
    end

    def valid?
      config_errors.nil?
    end

    def project_url
      "#{redmine_url}/#{project_name}"
    end

    def redmine_url
      config['redmineurl']
    end

    def project_name
      config['projectid']
    end

    def repository_name
      if config.key?('repositoryid') && !config['repositoryid'].empty?
        "#{project_name}/#{config['repositoryid']}"
      else
        project_name
      end
    end

    def repository_key
      config['repositorykey']
    end

    def debug_mode?
      config['debugmode'] == 'true'
    end

    def loglevel
      if debug_mode?
        'debug'
      else
        'info'
      end
    end

    def post_data
      post_data = {}
      post_data['clear_time']   = clear_time
      post_data['encoded_time'] = auth_token
      config.each_key do |key|
        post_data[key] = config[key] unless IGNORE_PARAMS.include?(key)
      end
      post_data
    end

    def clear_time
      @clear_time ||= Time.new.utc.to_i.to_s
    end

    def auth_token
      Digest::SHA1.hexdigest(clear_time.to_s + repository_key)
    end

    # Detect blank params in config.
    # Allow blank repositoryid (as default).
    #
    def config_errors
      config.detect { |k, v| k != 'repositoryid' && v == '' }
    end

    private

    def load_gitolite_vars
      REDMINE_PARAMS.each do |var_name|
        var_value = get_gitolite_config(var_name)
        var_name = sanitize(var_name)
        @config[var_name] = var_value
      end
    end

    def get_gitolite_config(var_name)
      (%x[git config #{var_name}]).chomp.strip
    end

    def sanitize(var_name)
      var_name.gsub(/^.*\./, '')
    end
  end
end
