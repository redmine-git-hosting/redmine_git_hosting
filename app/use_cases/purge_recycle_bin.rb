class PurgeRecycleBin
  unloadable

  include UseCaseBase

  attr_reader :repositories
  attr_reader :options


  def initialize(repositories, opts = {})
    @repositories = repositories
    @options      = opts
    super
  end


  def call
    purge_trash_bin
    super
  end


  private


    def purge_trash_bin
      resync_gitolite(:purge_recycle_bin, repositories)
    end

end
