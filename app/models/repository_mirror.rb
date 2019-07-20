class RepositoryMirror < ActiveRecord::Base
  include Redmine::SafeAttributes

  PUSHMODE_MIRROR       = 0
  PUSHMODE_FORCE        = 1
  PUSHMODE_FAST_FORWARD = 2

  ## Attributes
  safe_attributes 'url', 'push_mode', 'include_all_branches', 'include_all_tags',
                  'explicit_refspec', 'active'

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, presence: true

  ## Only allow SSH format
  ## ssh://git@redmine.example.org/project1/project2/project3/project4.git
  ## ssh://git@redmine.example.org:2222/project1/project2/project3/project4.git
  validates :url, presence: true,
                  uniqueness: { case_sensitive: false, scope: :repository_id },
                  format: { with: RedmineGitHosting::Validators::GIT_SSH_URL_REGEX }

  validates :push_mode, presence: true,
                        numericality: { only_integer: true },
                        inclusion: { in: [PUSHMODE_MIRROR, PUSHMODE_FORCE, PUSHMODE_FAST_FORWARD] }

  ## Additional validations
  validate :mirror_configuration

  ## Scopes
  scope :active,               -> { where(active: true) }
  scope :inactive,             -> { where(active: false) }
  scope :has_explicit_refspec, -> { where(push_mode: '> 0') }

  ## Callbacks
  before_validation :strip_whitespace

  def mirror_mode?
    push_mode == PUSHMODE_MIRROR
  end

  def force_mode?
    push_mode == PUSHMODE_FORCE
  end

  def push_mode_to_s
    case push_mode
    when 0
      'mirror'
    when 1
      'force'
    when 2
      'fast_forward'
    end
  end

  private

  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = url.strip rescue ''
    self.explicit_refspec = explicit_refspec.strip rescue ''
  end

  def mirror_configuration
    if mirror_mode?
      reset_fields
    elsif include_all_branches? && include_all_tags?
      mutual_exclusion_error
    elsif explicit_refspec.present?
      if include_all_branches?
        errors.add(:explicit_refspec, "cannot be used with #{l(:label_mirror_include_all_branches)}.")
      else
        validate_refspec
      end
    elsif !include_all_branches? && !include_all_tags?
      errors.add(:base, :nothing_to_push)
    end
  end

  # Check format of refspec
  #
  def validate_refspec
    RedmineGitHosting::Validators.valid_git_refspec_path?(explicit_refspec)
  rescue RedmineGitHosting::Error::InvalidRefspec::BadFormat => e
    errors.add(:explicit_refspec, :bad_format)
  rescue RedmineGitHosting::Error::InvalidRefspec::NullComponent => e
    errors.add(:explicit_refspec, :have_null_component)
  end

  def reset_fields
    # clear out all extra parameters.. (we use javascript to hide them anyway)
    self.include_all_branches = false
    self.include_all_tags     = false
    self.explicit_refspec     = ''
  end

  def mutual_exclusion_error
    errors.add(:base, "Cannot #{l(:label_mirror_include_all_branches)} and #{l(:label_mirror_include_all_tags)} at the same time.")
    return if explicit_refspec.blank?

    errors.add(:explicit_refspec, "cannot be used with #{l(:label_mirror_include_all_branches)} or #{l(:label_mirror_include_all_tags)}")
  end
end
