module GitoliteLogger

  @@logger_global       = nil
  @@logger_worker       = nil
  @@logger_recycle_bin  = nil
  @@logger_git_cache    = nil
  @@logger_smart_http   = nil
  @@logger_git_hooks    = nil


  def self.get_logger(type)
    file   = File.join(Rails.root, 'log', 'git_hosting.log').to_s

    if GitHostingConf.gitolite_log_split? && !File.directory?(File.join(Rails.root, 'log', 'git_hosting').to_s)
      FileUtils.mkdir_p(File.join(Rails.root, 'log', 'git_hosting').to_s)
    end

    case type
      when :global then
        file   = File.join(Rails.root, 'log', 'git_hosting', 'git_hosting.log').to_s if GitHostingConf.gitolite_log_split?
        prefix = '[GitHosting]'
        @@logger_global ||= LoggerGlobal.new(file, prefix)

      when :worker then
        file   = File.join(Rails.root, 'log', 'git_hosting', 'git_worker.log').to_s if GitHostingConf.gitolite_log_split?
        prefix = '[GitWorker]'
        @@logger_worker ||= LoggerGlobal.new(file, prefix)

      when :recycle_bin then
        file   = File.join(Rails.root, 'log', 'git_hosting', 'git_recycle_bin.log').to_s if GitHostingConf.gitolite_log_split?
        prefix = '[GitRecycleBin]'
        @@logger_git_cache ||= LoggerGlobal.new(file, prefix)

      when :git_cache then
        file   = File.join(Rails.root, 'log', 'git_hosting', 'git_cache.log').to_s if GitHostingConf.gitolite_log_split?
        prefix = '[GitCache]'
        @@logger_git_cache ||= LoggerGlobal.new(file, prefix)

      when :smart_http then
        file   = File.join(Rails.root, 'log', 'git_hosting', 'git_smart_http.log').to_s if GitHostingConf.gitolite_log_split?
        prefix = '[GitSmartHttp]'
        @@logger_smart_http ||= LoggerGlobal.new(file, prefix)

      when :git_hooks then
        file   = File.join(Rails.root, 'log', 'git_hosting', 'git_hooks.log').to_s if GitHostingConf.gitolite_log_split?
        prefix = '[GitHooks]'
        @@logger_git_hooks ||= LoggerGlobal.new(file, prefix)

    end
  end


  class LoggerGlobal

    def initialize(file, prefix)
      @file   = file
      @prefix = prefix
      @logger = nil
      get_logger
    end


    def get_logger
      logfile = File.open(@file, 'a')
      logfile.sync = true
      @logger = CustomLogger.new(logfile)
      @logger.level = get_log_level
    end


    def get_log_level
      case GitHostingConf.gitolite_log_level
        when 'debug' then
          return Logger::DEBUG
        when 'info' then
          return Logger::INFO
        when 'warn' then
          return Logger::WARN
        when 'error' then
          return Logger::ERROR
      end
    end


    def debug(*progname, &block)
      if block_given?
        @logger.debug(*progname) { "#{@prefix} #{yield}".gsub(/\n/,"\n#{@prefix}") }
      else
        @logger.debug "#{@prefix} #{progname}".gsub(/\n/,"\n#{@prefix}")
      end
    end


    def info(*progname, &block)
      if block_given?
        @logger.info(*progname) { "#{@prefix} #{yield}".gsub(/\n/,"\n#{@prefix}") }
      else
        @logger.info "#{@prefix} #{progname}".gsub(/\n/,"\n#{@prefix}")
      end
    end


    def warn(*progname, &block)
      if block_given?
        @logger.warn(*progname) { "#{@prefix} #{yield}".gsub(/\n/,"\n#{@prefix}") }
      else
        @logger.warn "#{@prefix} #{progname}".gsub(/\n/,"\n#{@prefix}")
      end
    end


    def error(*progname, &block)
      if block_given?
        @logger.error(*progname) { "#{@prefix} #{yield}".gsub(/\n/,"\n#{@prefix}") }
      else
        @logger.error "#{@prefix} #{progname}".gsub(/\n/,"\n#{@prefix}")
      end
    end


    # Handle everything else with base object
    def method_missing(m, *args, &block)
      @logger.send m, *args, &block
    end
  end


  class CustomLogger < Logger
    def flush
      return true
    end

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp} #{severity} #{msg}\n"
    end
  end

end
