class RepositoryMirror < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE   = true
  STATUS_INACTIVE = false

  PUSHMODE_MIRROR       = 0
  PUSHMODE_FORCE        = 1
  PUSHMODE_FAST_FORWARD = 2

  ## Attributes
  attr_accessible :url, :push_mode, :include_all_branches, :include_all_tags, :explicit_refspec, :active

  ## Relations
  belongs_to :repository

  ## Validations
  validates :repository_id, :presence => true

  ## Only allow SSH format
  ## ssh://git@redmine.example.org/project1/project2/project3/project4.git
  ## ssh://git@redmine.example.org:2222/project1/project2/project3/project4.git
  validates :url, :presence   => true,
                  :uniqueness => { :case_sensitive => false, :scope => :repository_id },
                  :format     => { :with => /\A(ssh:\/\/)([\w\.@]+)(\:[\d]+)?([\w\/\-~]+)(\.git)?\z/i }

  validates :push_mode, :presence     => true,
                        :numericality => { :only_integer => true },
                        :inclusion    => { :in => [PUSHMODE_MIRROR, PUSHMODE_FORCE, PUSHMODE_FAST_FORWARD] }

  validate :check_refspec

  validates_associated :repository

  ## Scopes
  scope :active,   -> { where active: STATUS_ACTIVE }
  scope :inactive, -> { where active: STATUS_INACTIVE }

  scope :has_explicit_refspec, -> { where push_mode: '> 0' }

  ## Callbacks
  before_validation :strip_whitespace

  include GitoliteHooksHelper


  def push
    stdin = [ 'cd', repository.gitolite_repository_path, '&&', 'env', 'GIT_SSH=$HOME/.ssh/run_gitolite_admin_ssh', 'git', 'push', *push_args, '2>&1' ].join(' ')
    begin
      push_message = RedmineGitolite::GitoliteWrapper.sudo_pipe_capture("sh", stdin)
      push_failed = false
    rescue RedmineGitolite::GitHosting::GitHostingException => e
      push_message = e.output
      push_failed = true
    end

    return push_failed, push_message
  end


  # If we have an explicit refspec, check it against incoming payloads
  # Special case: if we do not pass in any payloads, return true
  def needs_push(payloads = [])
    return true if payloads.empty?
    return true if push_mode == PUSHMODE_MIRROR

    refspec_parse = explicit_refspec.match(/^\+?([^:]*)(:[^:]*)?$/)
    payloads.each do |payload|
      if splitpath = refcomp_parse(payload[:ref])
        return true if payload[:ref] == refspec_parse[1]  # Explicit Reference Spec complete path
        return true if splitpath[:name] == refspec_parse[1] # Explicit Reference Spec no type
        return true if include_all_branches && splitpath[:type] == "heads"
        return true if include_all_tags && splitpath[:type] == "tags"
      end
    end
    false
  end


  def push_args
    push_args = []

    if self.push_mode == PUSHMODE_MIRROR
      push_args << "--mirror"
    else
      # Not mirroring -- other possible push_args
      push_args << "--force" if self.push_mode == PUSHMODE_FORCE
      push_args << "--all"   if self.include_all_branches?
      push_args << "--tags"  if self.include_all_tags?
    end

    push_args << self.url
    push_args << "#{dequote(self.explicit_refspec)}" unless self.explicit_refspec.blank?

    return push_args
  end


  private


  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = url.strip rescue ''
    self.explicit_refspec = explicit_refspec.strip rescue ''
  end


  # Put backquote in front of crucial characters
  def dequote(in_string)
    in_string.gsub(/[$,"\\\n]/) {|x| "\\" + x}
  end


  def check_refspec
    if push_mode == PUSHMODE_MIRROR
      # clear out all extra parameters.. (we use javascript to hide them anyway)
      self.include_all_branches = false
      self.include_all_tags     = false
      self.explicit_refspec     = ""
      return true

    elsif include_all_branches && include_all_tags
      errors.add(:base, "Cannot #{l(:label_mirror_include_all_branches)} and #{l(:label_mirror_include_all_tags)} at the same time.")
      errors.add(:explicit_refspec, "cannot be used with #{l(:label_mirror_include_all_branches)} or #{l(:label_mirror_include_all_tags)}") unless explicit_refspec.blank?
      return false

    elsif !explicit_refspec.blank?
      errors.add(:explicit_refspec, "cannot be used with #{l(:label_mirror_include_all_branches)}.") if include_all_branches

      # Check format of refspec
      if !(refspec_parse = explicit_refspec.match(/^\+?([^:]*)(:([^:]*))?$/)) || !refcomp_valid(refspec_parse[1]) || !refcomp_valid(refspec_parse[3])
        errors.add(:explicit_refspec, "is badly formatted.")
      elsif !refspec_parse[1] || refspec_parse[1] == ""
        errors.add(:explicit_refspec, "cannot have null first component (will delete remote branch(s))")
      end

      return false

    elsif !include_all_branches && !include_all_tags
      errors.add(:base, "Must include at least one item to push.")
      return false
    end
  end


  def refcomp_valid(spec)
    # Allow null or empty components
    if !spec || spec == "" || refcomp_parse(spec)
      true
    else
      false
    end
  end

end
