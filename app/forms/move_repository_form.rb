class MoveRepositoryForm
  include BaseForm

  attr_reader   :repository
  attr_accessor :project_id

  validates_presence_of :project_id
  validate :repository_is_movable
  validate :target_project
  validate :repository_uniqueness

  def initialize(repository)
    @repository = repository
  end

  def project
    @project ||= Project.find_by_id(project_id)
  end

  def valid_form_submitted
    repository.update_attribute(:project_id, project.id)
    RedmineGitHosting::GitoliteAccessor.move_repository(repository)
  end

  private

  def repository_is_movable
    errors.add(:base, :identifier_empty) unless repository.movable?
  end

  def target_project
    errors.add(:base, :wrong_target_project) if repository.project == project
  end

  def repository_uniqueness
    new_repo = project.repositories.find_by_identifier(repository.identifier)
    errors.add(:base, :identifier_taken) unless new_repo.nil?
  end
end
