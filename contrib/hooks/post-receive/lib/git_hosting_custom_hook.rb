module GitHosting
  class CustomHook

    attr_reader :repo_path
    attr_reader :refs


    def initialize(repo_path, refs)
      @repo_path = repo_path
      @refs      = refs
    end


    def exec
      ## Execute extra hooks
      extra_hooks = get_extra_hooks
      if !extra_hooks.empty?
        logger("Calling additional post-receive hooks...")
        call_extra_hooks(extra_hooks)
      end
    end


    private


      def get_extra_hooks
        # Get global extra hooks
        logger('Looking for additional global post-receive hooks...')
        global_extra_hooks = get_executables('hooks/post-receive.d')
        logger('  - No global hooks found') if global_extra_hooks.empty?

        logger('')

        # Get local extra hooks
        logger('Looking for additional local post-receive hooks...')
        local_extra_hooks = get_executables('hooks/post-receive.local.d')
        logger('  - No local hooks found') if local_extra_hooks.empty?

        logger('')

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
          logger("  - Executing extra hook '#{extra_hook}'")

          IO.popen("#{extra_hook}", "w+") do |pipe|
            begin
              pipe.puts refs
              pipe.close_write
              logger("#{pipe.read}")
            rescue => e
              logger("Error while executing hook #{extra_hook}")
              logger("#{e.message}")
            end
          end
        end
      end


      def logger(message)
        puts "#{message}\n"
      end

  end
end
