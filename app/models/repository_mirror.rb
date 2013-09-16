class RepositoryMirror < ActiveRecord::Base
  unloadable

  STATUS_ACTIVE = 1
  STATUS_INACTIVE = 0

  PUSHMODE_MIRROR = 0
  PUSHMODE_FORCE = 1
  PUSHMODE_FAST_FORWARD = 2

  belongs_to :repository

  attr_accessible :url, :push_mode, :include_all_branches, :include_all_tags, :explicit_refspec, :active

  ## Only allow SSH format
  ## git@github.com:user/project.git
  ## git-test@redmine.example.org:my_user/test.git
  ## git-test@redmine.example/project1/project2/project3/project4.git
  validates_format_of     :url, :with => /^([A-Za-z0-9\-]+@)([A-Za-z0-9\.\-]+)(:|\/)([A-Za-z0-9\_\-\/]+)(\.git)?$/i, :allow_blank => false

  validates_uniqueness_of :url, :scope => [:repository_id]
  validates_presence_of   :repository_id, :url
  validates_associated    :repository

  validate :check_refspec

  before_validation :strip_whitespace

  if Rails::VERSION::MAJOR >= 3 && Rails::VERSION::MINOR >= 1
    scope :active, {:conditions => {:active => RepositoryMirror::STATUS_ACTIVE}}
    scope :inactive, {:conditions => {:active => RepositoryMirror::STATUS_INACTIVE}}

    scope :has_explicit_refspec, {:conditions => ['push_mode > 0']}
  else
    named_scope :active, {:conditions => {:active => RepositoryMirror::STATUS_ACTIVE}}
    named_scope :inactive, {:conditions => {:active => RepositoryMirror::STATUS_INACTIVE}}

    named_scope :has_explicit_refspec, {:conditions => ['push_mode > 0']}
  end

  def push
    repo_path = GitHosting.repository_path(repository)

    push_args = ""
    if push_mode == PUSHMODE_MIRROR
      push_args << "--mirror "
    else
      # Not mirroring -- other possible push_args
      push_args << "--force " if push_mode == PUSHMODE_FORCE
      push_args << "--all "   if include_all_branches
      push_args << "--tags "  if include_all_tags
    end
    push_args << "\"#{dequote(url)}\" "
    push_args << "\"#{dequote(explicit_refspec)}\" " unless explicit_refspec.blank?

    shellout = %x[ echo 'cd "#{repo_path}" ; env GIT_SSH=~/.ssh/run_gitolite_admin_ssh git push #{push_args} 2>&1' | #{GitHosting.shell_cmd_runner} "bash" ].chomp
    push_failed = ($?.to_i != 0) ? true : false

    if (push_failed)
      logger.error "Pushing changes to mirror '#{url}'... Failed!"
      logger.error "  " + shellout.split("\n").join("\n  ")
    else
      logger.info "Pushing changes to mirror '#{url}'... Succeeded!"
    end
    [push_failed, shellout]
  end

  # If we have an explicit refspec, check it against incoming payloads
  # Special case: if we do not pass in any payloads, return true
  def needs_push(payloads=[])
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

  def to_s
    return File.join("#{repository.project.identifier}-#{url}")
  end

  protected

  @@logger = nil
  def logger
    @@logger ||= GitoliteLogger.get_logger(:git_hooks)
  end

  # Strip leading and trailing whitespace
  def strip_whitespace
    self.url = url.strip
    self.explicit_refspec = explicit_refspec.strip
  end

  # Put backquote in front of crucial characters
  def dequote(in_string)
    in_string.gsub(/[$,"\\\n]/) {|x| "\\" + x}
  end

  def check_refspec
    self.explicit_refspec = explicit_refspec.strip

    if push_mode == PUSHMODE_MIRROR
      # clear out all extra parameters.. (we use javascript to hide them anyway)
      self.include_all_branches = false
      self.include_all_tags = false
      self.explicit_refspec = ""
    elsif include_all_branches && include_all_tags
      errors.add(:base, "Cannot #{l(:field_include_all_branches)} and #{l(:field_include_all_tags)} at the same time.")
      errors.add(:explicit_refspec, "cannot be used with #{l(:field_include_all_branches)} or #{l(:field_include_all_tags)}") unless explicit_refspec.blank?
    elsif !explicit_refspec.blank?
      errors.add(:explicit_refspec, "cannot be used with #{l(:field_include_all_branches)}.") if include_all_branches

      # Check format of refspec
      if !(refspec_parse = explicit_refspec.match(/^\+?([^:]*)(:([^:]*))?$/)) || !refcomp_valid(refspec_parse[1]) || !refcomp_valid(refspec_parse[3])
        errors.add(:explicit_refspec, "is badly formatted.")
      elsif !refspec_parse[1] || refspec_parse[1]==""
        errors.add(:explicit_refspec, "cannot have null first component (will delete remote branch(s))")
      end
    elsif !include_all_branches && !include_all_tags
      errors.add(:base, "Must include at least one item to push.")
    end
  end

  def refcomp_valid(spec)
    # Allow null or empty components
    if !spec || spec=="" || refcomp_parse(spec)
      true
    else
      false
    end
  end

  # Parse a reference component.  Three possibilities:
  #
  # 1) refs/type/name
  # 2) name
  #
  # here, name can have many components.
  @@refcomp = "[\\.\\-\\w_\\*]+"
  def refcomp_parse(spec)
    if (refcomp_parse = spec.match(/^(refs\/)?((#{@@refcomp})\/)?(#{@@refcomp}(\/#{@@refcomp})*)$/))
      if refcomp_parse[1]
        # Should be first class.  If no type component, return fail
        if refcomp_parse[3]
          {:type => refcomp_parse[3], :name => refcomp_parse[4]}
        else
          nil
        end
      elsif refcomp_parse[3]
        {:type => nil, :name => (refcomp_parse[3] + "/" + refcomp_parse[4])}
      else
        {:type => nil, :name => refcomp_parse[4]}
      end
    else
      nil
    end
  end

end
