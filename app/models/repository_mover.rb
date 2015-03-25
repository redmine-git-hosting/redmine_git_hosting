class RepositoryMover
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :repository_id, :project_id

  validates_presence_of :repository_id, :project_id
  validate :repository_identifier
  validate :repository_uniqueness


  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end


  def project
    Project.find_by_id(project_id)
  end


  def repository
    Repository.find_by_id(repository_id)
  end


  def persisted?
    false
  end


  private


    def repository_identifier
      errors.add(:base, :identifier_empty) if (repository.identifier.nil? || repository.identifier.blank?)
    end


    def repository_uniqueness
      new_repo = project.repositories.find_by_identifier(repository.identifier)
      errors.add(:base, :identifier_taken) if !new_repo.nil?
    end

end
