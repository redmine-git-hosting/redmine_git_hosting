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
#
class GitHostingCache
  # Redirector states
  WAIT_TO_CHECK = 0
  RUNNING_SHELL = 1
  STRING_IO     = 2
  DEAD          = 3


  @@logger = nil
  def self.logger
    @@logger ||= GitoliteLogger.get_logger(:git_cache)
  end


  # Primary interface: execute given command and send IO to block
  # options[:write_stdin] will derive caching key from data that block writes to io stream
  def self.execute(cmd_str, repo_id, options={}, &block)
    if max_cache_time == 0 || repo_id.nil? || options[:uncached]
      # Disabled cache, simply launch shell, don't redirect
      # Rails.logger.error "Cache disabled: repo_id(#{repo_id}), cmd_str: #{cmd_str}"
      options.delete(:uncached)
      retio = options.empty? ? Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str, &block) : Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str, options, &block)
      status = $?
    elsif !options[:write_stdin] && out = self.check_cache(cmd_str)
      # Simple case -- have cached result that depends only on cmd_str
      block.call(out)
      status = nil
      retio = out
    else
      # Create redirector stream and call block
      redirector = self.new(cmd_str, repo_id, options)
      block.call(redirector)
      (retio,status) = redirector.exit_shell
    end

    if status && status.exitstatus != 0
      raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "git exited with non-zero status: #{$?.exitstatus}"
    end
    retio
  end

  ###############################################
  # Duck-typing of an IO interface              #
  ###############################################
  def respond_to?(my_method)
    IO.instance_methods.map(&:to_sym).include?(my_method.to_sym) || super(my_method, *args, &block)
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
    out = self.class.check_cache(@my_cmd_str,@my_extra_args)
    if out
      # Match in the cache!
      @state = STRING_IO
      @my_read_stream = @retio = out
    else
      startup_shell
    end
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
      raise Redmine::Scm::Adapters::GitAdapter::ScmCommandAborted, "call to #{my_method.to_s} before IO-handlers wrapped."
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
          @my_read_stream.#{my_method}(*args,&block)
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
        @my_read_stream.#{my_method}(*args,&block)
      end
      EOF
    end
    # Call new function once
    self.send(my_method,*args,&block)
  end

  # This class wraps a given enumerator and produces another one
  # that logs all read data into the buffer.
  class EnumerableRedirector
    include Enumerable

    def initialize(my_enum,my_redirector)
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
    if @my_buffer.length + nextchunk.length <= self.class.max_cache_size
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

  ###############################################
  # Basic redirector methods                    #
  ###############################################

  def initialize(cmd_str, repo_id, options={})
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
    @wrap_thread = Thread.new(@my_cmd_str,@my_options) {|cmd_str,options|
      if options[:write_stdin]
        @retio = Redmine::Scm::Adapters::AbstractAdapter.shellout(cmd_str,options) {|io|
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
        self.class.set_cache(@my_repo_id,@my_buffer,@my_cmd_str,@my_extra_args)
        # Insert result into cache
      end
    end
    [@retio,@status]
  end

  ###############################################
  # Caching interface functions                 #
  ###############################################

  def self.max_cache_time
    GitHostingConf.gitolite_cache_max_time.to_i          # in seconds, default = 60
  end

  def self.max_cache_elements
    GitHostingConf.gitolite_cache_max_elements.to_i      # default = 100
  end

  def self.max_cache_size
    GitHostingConf.gitolite_cache_max_size.to_i*1024*1024   # In MB, default = 16MB, converted to bytes
  end

  def self.compose_key(key1,key2)
    if key2 && !key2.blank?
      key1 + "\n" + key2
    else
      key1
    end
  end

  def self.check_cache(primary_key,secondary_key=nil)
    # Rails.logger.error "Probing cache with key: #{compose_key(primary_key,secondary_key)}"
    out=nil
    cached = GitCache.find_by_command(compose_key(primary_key,secondary_key))
    if cached
      cur_time = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
      if (cached.created_at.to_i >= expire_at(cached.repo_identifier)) && (cur_time.to_i - cached.created_at.to_i < max_cache_time || max_cache_time < 0)
        # cached.touch # Update updated_at flag
        out = cached.command_output == nil ? "" : cached.command_output
      else
        GitCache.destroy(cached.id)
      end
    end
    if out
      # Return result as a string stream
      # Rails.logger.error "********* Matched ***********\n#{out.to_s}"
      StringIO.new(out)
    else
      # Rails.logger.error "********* Failed ************\n"
      nil
    end
  end


  def self.set_cache(repo_id,out_value,primary_key,secondary_key=nil)
  # Rails.logger.error "Inserting into cache with key: #{compose_key(primary_key,secondary_key)}"
    gitc = GitCache.create(
      :command         => compose_key(primary_key, secondary_key),
      :command_output  => out_value,
      :repo_identifier => repo_id
    )
    gitc.save
    if GitCache.count > max_cache_elements && max_cache_elements >= 0
      oldest = GitCache.find(:last, :order => "created_at DESC")
      GitCache.destroy(oldest.id)
    end
  end


  @@time_limits=nil
  def self.limit_cache(repo,date)
    repo_id = repo.is_a?(Repository) ? repo.git_label(:assume_unique => false) : Repository.repo_path_to_git_label(repo)
    # Rails.logger.error "EXECUTING LIMIT CACHE: '#{repo_id}' for '#{date}'"
    @@time_limits ||= {}
    @@time_limits[repo_id]=(ActiveRecord::Base.default_timezone == :utc ? date.utc : date).to_i
  end


  def self.expire_at(repo_id)
    @@time_limits ? @@time_limits[repo_id] : 0
  end


  # Given repository or repository_path, clear the cache entries
  def self.clear_cache_for_repository(repo)
    repo_id = repo.is_a?(Repository) ? repo.git_label(:assume_unique => false) : Repository.repo_path_to_git_label(repo)

    # Clear cache
    old_cached = GitCache.find_all_by_repo_identifier(repo_id)
    if old_cached != nil
      old_ids = old_cached.collect(&:id)
      GitCache.destroy(old_ids)
      logger.info "Removed #{old_cached.count} expired cache entries."
    end
  end


  # After resetting cache timing parameters -- delete entries that no-longer match
  def self.clear_obsolete_cache_entries
    return if max_cache_time < 0  # No expiration needed

    target_limit = Time.now - max_cache_time
    old_cached = GitCache.all(:conditions => ["created_at < ?", target_limit])
    if old_cached != nil
      old_ids = old_cached.collect(&:id)
      GitCache.destroy(old_ids)
      logger.info "Removed #{old_cached.count} expired cache entries."
    end
  end

end
