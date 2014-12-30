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
      push_message = RedmineGitHosting::Commands.sudo_pipe_capture("sh", push_command)
      push_failed = false
    rescue RedmineGitHosting::Error::GitoliteCommandException => e
      push_message = e.output
      push_failed = true
    end

    return push_failed, push_message
  end


  private


    def push_command
      [ 'cd', repository.gitolite_repository_path, '&&', 'env', 'GIT_SSH=$HOME/.ssh/run_gitolite_admin_ssh', 'git', 'push', *push_args, '2>&1' ].join(' ')
    end


    def push_args
      push_args = []

      if mirror.push_mode == RepositoryMirror::PUSHMODE_MIRROR
        push_args << "--mirror"
      else
        # Not mirroring -- other possible push_args
        push_args << "--force" if mirror.push_mode == RepositoryMirror::PUSHMODE_FORCE
        push_args << "--all"   if mirror.include_all_branches?
        push_args << "--tags"  if mirror.include_all_tags?
      end

      push_args << mirror.url
      push_args << "#{dequote(mirror.explicit_refspec)}" unless mirror.explicit_refspec.blank?

      return push_args
    end


    # Put backquote in front of crucial characters
    def dequote(in_string)
      in_string.gsub(/[$,"\\\n]/) {|x| "\\" + x}
    end

end
