class MoveRepositoriesTree
  unloadable

  include UseCaseBase

  attr_reader :count


  def initialize(count)
    @count = count
    super
  end


  def call
    move_repositories_tree
    super
  end


  private


    def move_repositories_tree
      logger.info("Gitolite configuration has been modified : repositories hierarchy")
      logger.info("Resync all projects (root projects : '#{count}')...")
      resync_gitolite(:move_repositories_tree, count)
    end

end
