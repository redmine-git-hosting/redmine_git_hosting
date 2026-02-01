# frozen_string_literal: true

class ProtectedBranchesMember < RedmineGitHosting.old_redmine? ? ActiveRecord::Base : ApplicationRecord
  include Redmine::SafeAttributes

  ## Attributes
  safe_attributes 'principal_id', 'inherited_by'

  ## Relations
  belongs_to :protected_branch, class_name: 'RepositoryProtectedBranche'
  belongs_to :principal

  ## Callbacks
  after_destroy :remove_dependent_objects

  private

  def remove_dependent_objects
    return unless principal.instance_of? Group

    principal.users.each do |user|
      member = self.class.find_by principal_id: user.id, inherited_by: principal.id
      member&.destroy!
    end
  end
end
