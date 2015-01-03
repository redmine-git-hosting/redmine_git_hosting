class MirrorPush
  unloadable

  attr_reader :mirror
  attr_reader :repository


  def initialize(mirror)
    @mirror     = mirror
    @repository = mirror.repository
  end


  def call
    push!
  end


  def push!
    begin
      push_message = RedmineGitHosting::Commands.sudo_git_mirror_push(repository.gitolite_repository_path, mirror.url, branch, push_args)
      push_failed = false
    rescue RedmineGitHosting::Error::GitoliteCommandException => e
      push_message = e.output
      push_failed = true
    end

    return push_failed, push_message
  end


  private


    def push_args
      if mirror.mirror_mode?
        ['--mirror']
      else
        # Not mirroring -- other possible push_args
        mirror_args
      end
    end


    def mirror_args
      push_args = []
      push_args << '--force' if mirror.force_mode?
      push_args << '--all'   if mirror.include_all_branches?
      push_args << '--tags'  if mirror.include_all_tags?
      push_args
    end


    def branch
      "#{dequote(mirror.explicit_refspec)}" unless mirror.explicit_refspec.blank?
    end


    # Put backquote in front of crucial characters
    def dequote(in_string)
      in_string.gsub(/[$,"\\\n]/) { |x| "\\" + x }
    end

end
