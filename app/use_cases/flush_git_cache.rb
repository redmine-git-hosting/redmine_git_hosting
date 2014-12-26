class FlushGitCache
  unloadable

  include UseCaseBase


  def call
    flush_git_cache
    super
  end


  private


    def flush_git_cache
      logger.info('Flush Git Cache !')
      ActiveRecord::Base.connection.execute('TRUNCATE git_caches')
    end

end
