require 'stringio'

module RedmineGitHosting
  class ShellRedirector

    # Rewritten version of caching functionality to accommodate Redmine 1.4+
    # When the shell is called with options[:write_stdin], then part of the
    # argument on which caching is based is written to the input stream of the shell.
    # Thus, we may need to wait for this write to occur before checking the cache.
    #
    # The basic mechanism here is a duck-typed IO stream (the CachedShellRedirector) which
    # intercepts the output of git and places it in the cache.  In addition, this mechanism
    # can intercept the stdin heading toward git so as to have a complete key for examining
    # the cache.
    #
    # Primary calling sequence is to use the "execute" method which will allocate a new
    # CachedShellRedirector only if required:

    # Redirector states
    WAIT_TO_CHECK = 0
    RUNNING_SHELL = 1
    STRING_IO     = 2
    DEAD          = 3


    def initialize(cmd_str, repo_id, options = {})
      @my_cmd_str = cmd_str
      @my_repo_id = repo_id
      @my_options = options
      @my_buffer = ""
      @my_buffer_overfull = false
      @my_extra_args = ""
      @my_read_stream = nil
      @status = nil
      if options[:write_stdin]
        @state = WAIT_TO_CHECK
      else
        startup_shell
      end
    end


    def startup_shell
      Thread.abort_on_exception = true
      proxy_started = false
      @wrap_thread = Thread.new(@my_cmd_str, @my_options) {|cmd_str, options|
        if options[:write_stdin]
          @retio = Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str, options) {|io|
            io.binmode
            io.puts(@my_extra_args)
            io.close_write
            @my_read_stream = io

            proxy_started = true

            # Wait before closing io
            Thread.stop
          }
        else
          @retio = Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str) {|io|
            @my_read_stream = io

            proxy_started = true

            # Wait before closing io
            Thread.stop
          }
        end
        @status = $?
      }

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
        if !@my_buffer_overfull
          # Insert result into cache
          RedmineGitHosting::CacheManager.set_cache(@my_repo_id, @my_buffer, @my_cmd_str, @my_extra_args)
        end
      end
      return [@retio, @status]
    end


    # Catch any extra args placed into stdin.  We explicitly code the
    # output (write) functions here.  Below, 'method_missing' traps the
    # read functions (since there are a lot of them) and any control functions
    # and dynamically defines them as needed.
    def puts(*args)
      @my_extra_args << args.join("\n") + "\n"
    end


    def putc(obj)
      @my_extra_args << retval_to_s(obj)
    end


    def write(obj)
      @my_extra_args << obj.to_s
    end


    # Ignore this -- must handle it before we have chosen output stream
    def binmode
    end


    def close_write
      # Ok -- now have all the extra args...  Check cache
      out = RedmineGitHosting::CacheManager.check_cache(@my_cmd_str, @my_extra_args)
      if out
        # Match in the cache!
        @state = STRING_IO
        @my_read_stream = @retio = out
      else
        startup_shell
      end
    end


    def logger
      RedmineGitHosting.logger
    end


    ###############################################
    # Duck-typing of an IO interface              #
    ###############################################
    def respond_to?(my_method)
      IO.instance_methods.map(&:to_sym).include?(my_method.to_sym) || super(my_method, *args, &block)
    end


    # On-the-fly compilation of any missing functions, including all of the
    # read functions (with and without blocks), which we divert into the buffer
    # for potential caching.  Other functions are compiled as "proxies", which
    # simply call the corresponding functions on the current read stream (@my_read_stream).
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
    def method_missing(my_method, *args, &block)
      # Only handle IO methods!
      unless IO.instance_methods.map(&:to_sym).include?(my_method.to_sym)
        return super(my_method, *args, &block)
      end

      if @my_read_stream.nil?
        # Shouldn't happen, but might be problem
        logger.error("Call to #{my_method.to_s} before IO-handlers wrapped.")
        raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "Call to #{my_method.to_s} before IO-handlers wrapped."
      end


      # Buffer up results from read operations. Proxy everything else directly to IO stream.
      my_name = my_method.to_s
      if my_name =~ /^(each|bytes)/
        # Handle Enumerator read functions (Class #1)
        self.class.class_eval <<-EOF, __FILE__, __LINE__
        def #{my_method}(*args, &block)
          if @state == RUNNING_SHELL
            # Must Divert results into buffer.
            if block_given?
              @my_read_stream.#{my_method}(*args) {|myvalue|
                add_to_buffer(myvalue)
                block.call(myvalue)
              }
            else
              myvalue = @my_read_stream.#{my_method}(*args)
              EnumerableRedirector.new(myvalue,self)
            end
          else
            @my_read_stream.#{my_method}(*args, &block)
          end
        end
        EOF
      elsif my_name =~ /^(get|read)/
        # Handle "regular" read functions (Class #2)
        self.class.class_eval <<-EOF, __FILE__, __LINE__
        def #{my_method}(*args, &block)
          myvalue = @my_read_stream.#{my_method}(*args)
          add_to_buffer(myvalue) if @state == RUNNING_SHELL
          myvalue
        end
        EOF
      else
        # Handle every thing else by simply forwarding (Class #3)
        self.class.class_eval <<-EOF, __FILE__, __LINE__
        def #{my_method}(*args, &block)
          @my_read_stream.#{my_method}(*args, &block)
        end
        EOF
      end
      # Call new function once
      self.send(my_method, *args, &block)
    end


    # This class wraps a given enumerator and produces another one
    # that logs all read data into the buffer.
    class EnumerableRedirector
      include Enumerable

      def initialize(my_enum, my_redirector)
        @my_enum = my_enum
        @my_redirector = my_redirector
      end

      def each
        return to_enum :each unless block_given?
        @my_enum.each do |myvalue|
          @my_redirector.add_to_buffer(myvalue)
          yield myvalue
        end
      end
    end


    def add_to_buffer(invalue)
      return if @my_buffer_overfull
      if invalue.is_a?(Array)
        invalue.each {|nextvalue| push_to_buffer nextvalue}
      else
        push_to_buffer invalue
      end
    end


    def push_to_buffer(invalue)
      nextchunk = invalue.is_a?(Integer) ? invalue.chr : invalue
      if @my_buffer.length + nextchunk.length <= RedmineGitHosting::CacheManager.max_cache_size
        @my_buffer << nextchunk
      else
        @my_buffer_overfull = true
      end
    end


    ##############################################################################
    # The following three functions are the generic versions of what is          #
    # currently "compiled" into function definitions above in missing_method().  #
    ##############################################################################

    # Class #1 functions (Read functions with block/enumerator behavior)
    def enumerator_diverter(my_method, *args, &block)
      if @state == RUNNING_SHELL
        # Must Divert results into buffer.
        if block_given?
          @my_read_stream.send(my_method, *args) {|myvalue|
            add_to_buffer(myvalue)
            block.call(myvalue)
          }
        else
          myvalue = @my_read_stream.send(my_method, *args)
          EnumerableRedirector.new(myvalue, self)
        end
      else
        @my_read_stream.send(my_method, *args, &block)
      end
    end


    # Class #2 functions (Return of Array, String, or Integer)
    def normal_diverter(my_method, *args)
      myvalue = @my_read_stream.send(my_method, *args)
      add_to_buffer(myvalue) if @state == RUNNING_SHELL
      myvalue
    end


    # Class #3 functions (Everything by read functions)
    def simple_proxy(my_method, *args, &block)
      @my_read_stream.send(my_method, *args, &block)
    end

  end
end
