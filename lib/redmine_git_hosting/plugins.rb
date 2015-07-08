module RedmineGitHosting
  module Plugins
    extend self

    def execute(step, repository, opts = {})
      begin
        Plugins::GitolitePlugin.all_plugins.each do |plugin|
          plugin.new(repository, opts).send(step) if plugin.method_defined?(step)
        end
      rescue => e
        RedmineGitHosting.logger.error e.message
      end
    end

  end
end
