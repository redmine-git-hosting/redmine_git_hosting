class FlushSettingsCache
  unloadable

  include UseCaseBase


  def call
    flush_settings_cache
    super
  end


  private


    def flush_settings_cache
      resync_gitolite(:flush_settings_cache, 'flush!', {flush_cache: true})
    end

end
