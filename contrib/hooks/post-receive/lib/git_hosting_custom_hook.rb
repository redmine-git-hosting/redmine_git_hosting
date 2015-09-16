module GitHosting
  class CustomHook

    attr_reader :repo_path
    attr_reader :refs
    attr_reader :git_config


    def initialize(repo_path, refs)
      @repo_path  = repo_path
      @refs       = refs
      @git_config = Config.new
    end


    def exec
      ## Execute extra hooks
      extra_hooks = get_extra_hooks
      if !extra_hooks.empty?
        logger.info('Calling additional post-receive hooks...')
        call_extra_hooks(extra_hooks)
        logger.info('')
      end
    end


    private


      def get_extra_hooks
        # Get global extra hooks
        logger.debug('Looking for additional global post-receive hooks...')
        global_extra_hooks = get_executables('hooks/post-receive.d')
        if global_extra_hooks.empty?
          logger.debug('  - No global hooks found')
        else
          logger.debug("  - Global hooks found : #{global_extra_hooks}")
        end

        logger.debug('')

        # Get local extra hooks
        logger.debug('Looking for additional local post-receive hooks...')
        local_extra_hooks = get_executables('hooks/post-receive.local.d')
        if local_extra_hooks.empty?
          logger.debug('  - No local hooks found')
        else
          logger.debug("  - Local hooks found : #{local_extra_hooks}")
        end

        logger.debug('')

        global_extra_hooks + local_extra_hooks
      end


      def get_executables(directory)
        executables = []
        if File.directory?(directory)
          Dir.foreach(directory) do |item|
            next if item == '.' or item == '..'
            # Use full relative path
            path = "#{directory}/#{item}"
            # Test if the file is executable
            if File.executable?(path)
              # Remember it, if so
              executables.push(path)
            end
          end
        end
        executables
      end


      def call_extra_hooks(extra_hooks)
        # Call each exectuble found with the parameters we got
        extra_hooks.each do |extra_hook|
          logger.info("  - Executing extra hook '#{extra_hook}'")

          IO.popen("#{extra_hook}", "w+") do |pipe|
            begin
              pipe.puts refs
              pipe.close_write
              logger.info("#{pipe.read}")
            rescue => e
              logger.error("Error while executing hook #{extra_hook}")
              logger.error("#{e.message}")
            end
          end
        end
      end


      def logger
        @logger ||= GitHosting::HookLogger.new(loglevel: git_config.loglevel)
      end

  end
end
