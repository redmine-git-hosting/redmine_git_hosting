class FlushGitCache
  unloadable

  include UseCaseBase


  def call
    flush_git_cache
    super
  end


  private


    def flush_git_cache
      RedmineGitolite::GitHosting.logger.info { 'Flush Git Cache !' }
      ActiveRecord::Base.connection.execute('TRUNCATE git_caches')
    end

end
