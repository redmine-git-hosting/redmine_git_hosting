require 'stringio'

module RedmineGitHosting
  class ShellRedirector

    # Redirector states
    WAIT_TO_CHECK = 0
    RUNNING_SHELL = 1
    STRING_IO     = 2
    DEAD          = 3


    class << self

      def logger
        RedmineGitHosting.logger
      end


      # Rewritten version of caching functionality to accommodate Redmine 1.4+
      # When the shell is called with options[:write_stdin], then part of the
      # argument on which caching is based is written to the input stream of the shell.
      # Thus, we may need to wait for this write to occur before checking the cache.
      #
      # The basic mechanism here is a duck-typed IO stream (the ShellRedirector) which
      # intercepts the output of Git and places it in the cache. In addition, this mechanism
      # can intercept the stdin heading toward Git so as to have a complete key for examining
      # the cache.
      #
      # Primary calling sequence is to use the "execute" method which will allocate a new
      # ShellRedirector only if required.
      #
      # This is the primary interface: execute given command and send IO to block.
      #
      # *options[:write_stdin]* will derive caching key from data that block writes to io stream.
      #
      def execute(cmd_str, repo_id, options = {}, &block)
        if !options[:write_stdin] && out = RedmineGitHosting::Cache.get_cache(repo_id, cmd_str)
          # Simple case -- have cached result that depends only on cmd_str
          block.call(out)
          retio = out
          status = nil
        else
          # Create redirector stream and call block
          redirector = self.new(cmd_str, repo_id, options)
          block.call(redirector)
          retio, status = redirector.exit_shell
        end

        if status && status.exitstatus.to_i != 0
          logger.error("Git exited with non-zero status : #{status.exitstatus} : #{cmd_str}")
          raise Redmine::Scm::Adapters::XitoliteAdapter::ScmCommandAborted, "Git exited with non-zero status : #{status.exitstatus} : #{cmd_str}"
        end

        return retio
      end

    end


    def initialize(cmd_str, repo_id, options = {})
      @cmd_str     = cmd_str
      @repo_id     = repo_id
      @options     = options
      @buffer      = ''
      @buffer_full = false
      @extra_args  = ''
      @read_stream = nil
      @status      = nil

      if options[:write_stdin]
        @state = WAIT_TO_CHECK
      else
        startup_shell
      end
    end


    def startup_shell
      Thread.abort_on_exception = true
      proxy_started = false
      @wrap_thread = Thread.new(@cmd_str, @options) do |cmd_str, options|
        if options[:write_stdin]
          @retio = Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str, options) do |io|
            io.binmode
            io.puts(@extra_args)
            io.close_write
            @read_stream = io

            proxy_started = true

            # Wait before closing io
            Thread.stop
          end
        else
          @retio = Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str) do |io|
            @read_stream = io

            proxy_started = true

            # Wait before closing io
            Thread.stop
          end
        end
        @status = $?
      end

      # Wait until subthread gets far enough
      while !proxy_started
        Thread.pass
      end
      @state = RUNNING_SHELL
    end


    def exit_shell
      # If shell was running, kill off wrapper thread
      if @state == RUNNING_SHELL
        @wrap_thread.run
        @wrap_thread.join
        @state = DEAD
        if !@buffer_full
          # Insert result into cache
          RedmineGitHosting::Cache.set_cache(@repo_id, @buffer, @cmd_str, @extra_args)
        end
      end
      return [@retio, @status]
    end


    # Catch any extra args placed into stdin.  We explicitly code the
    # output (write) functions here.  Below, 'method_missing' traps the
    # read functions (since there are a lot of them) and any control functions
    # and dynamically defines them as needed.
    #
    def puts(*args)
      @extra_args << args.join("\n") + "\n"
    end


    def write(obj)
      @extra_args << obj.to_s
    end


    # Ignore this -- must handle it before we have chosen output stream
    #
    def binmode
    end


    def close_write
      cached = RedmineGitHosting::Cache.get_cache(@repo_id, @cmd_str, @extra_args)
      if cached
        @state = STRING_IO
        @read_stream = @retio = cached
      else
        startup_shell
      end
    end


    def logger
      RedmineGitHosting.logger
    end


    # This class wraps a given enumerator and produces another one
    # that logs all read data into the buffer.
    #
    class EnumerableRedirector
      include Enumerable

      def initialize(enum, redirector)
        @enum       = enum
        @redirector = redirector
      end

      def each
        return to_enum :each unless block_given?
        @enum.each do |value|
          @redirector.add_to_buffer(value)
          yield value
        end
      end
    end


    def add_to_buffer(value)
      return if @buffer_full
      if value.is_a?(Array)
        value.each { |next_value| push_to_buffer(next_value) }
      else
        push_to_buffer(value)
      end
    end


    def push_to_buffer(value)
      next_chunk = value.is_a?(Integer) ? value.chr : value
      if @buffer.length + next_chunk.length <= RedmineGitHosting::Cache.max_cache_size
        @buffer << next_chunk
      else
        @buffer_full = true
      end
    end


    ###############################################
    # Duck-typing of an IO interface              #
    ###############################################

    def respond_to?(method)
      io_method?(method) || super(method, *args, &block)
    end


    def io_method?(method)
      IO.instance_methods.map(&:to_sym).include?(method.to_sym)
    end


    # On-the-fly compilation of any missing functions, including all of the
    # read functions (with and without blocks), which we divert into the buffer
    # for potential caching.  Other functions are compiled as "proxies", which
    # simply call the corresponding functions on the current read stream (@read_stream).
    # In this way, we pretty much get a complete I/O interface which diverts the
    # returns from reads.
    #
    # Note that missing I/O functions are of 3 classes here:
    # 1) Those that take a block and/or return enumerators
    # 2) Those that returns Array, String, or Integer
    # 3) Everything else
    #
    # The little bit of trickery with "class_eval" below is to compile custom functions
    # for each encountered missing function (so that method_missing only gets called
    # once for each function.  Note that we don't use define_method here, since
    # Ruby 1.8 define_method doesn't work with blocks.
    #
    # This will handle IO methods only!
    #
    def method_missing(method, *args, &block)
      return super(method, *args, &block) unless io_method?(method)

      # Shouldn't happen, but might be problem
      if @read_stream.nil?
        logger.error("Call to #{method} before IO-handlers wrapped.")
        raise Redmine::Scm::Adapters::XitoliteAdapter::ScmCommandAborted, "Call to #{method} before IO-handlers wrapped."
      end

      # Buffer up results from read operations. Proxy everything else directly to IO stream.
      method_name = method.to_s

      if method_name =~ /^(each|bytes)/
        inject_enumerator_method(method)
      elsif method_name =~ /^(get|read)/
        inject_read_method(method)
      else
        inject_proxy_method(method)
      end

      # Call new function once
      self.send(method, *args, &block)
    end


    def inject_enumerator_method(method)
      self.class.class_eval <<-EOF, __FILE__, __LINE__
      def #{method}(*args, &block)
        if @state == RUNNING_SHELL
          # Must Divert results into buffer.
          if block_given?
            @read_stream.#{method}(*args) do |value|
              add_to_buffer(value)
              block.call(value)
            end
          else
            value = @read_stream.#{method}(*args)
            EnumerableRedirector.new(value, self)
          end
        else
          @read_stream.#{method}(*args, &block)
        end
      end
      EOF
    end


    def inject_read_method(method)
      self.class.class_eval <<-EOF, __FILE__, __LINE__
      def #{method}(*args, &block)
        value = @read_stream.#{method}(*args)
        add_to_buffer(value) if @state == RUNNING_SHELL
        value
      end
      EOF
    end


    def inject_proxy_method(method)
      self.class.class_eval <<-EOF, __FILE__, __LINE__
      def #{method}(*args, &block)
        @read_stream.#{method}(*args, &block)
      end
      EOF
    end


    ##############################################################################
    # The following three functions are the generic versions of what is          #
    # currently "compiled" into function definitions above in missing_method().  #
    ##############################################################################

    # Class #1 functions (Read functions with block/enumerator behavior)
    #
    def enumerator_diverter(method, *args, &block)
      if @state == RUNNING_SHELL
        # Must Divert results into buffer.
        if block_given?
          @read_stream.send(method, *args) do |value|
            add_to_buffer(value)
            block.call(value)
          end
        else
          value = @read_stream.send(method, *args)
          EnumerableRedirector.new(value, self)
        end
      else
        @read_stream.send(method, *args, &block)
      end
    end


    # Class #2 functions (Return of Array, String, or Integer)
    #
    def normal_diverter(method, *args)
      value = @read_stream.send(method, *args)
      add_to_buffer(value) if @state == RUNNING_SHELL
      value
    end


    # Class #3 functions (Everything by read functions)
    #
    def simple_proxy(method, *args, &block)
      @read_stream.send(method, *args, &block)
    end

  end
end
