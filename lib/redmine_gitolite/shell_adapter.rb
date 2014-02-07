# == Githosting Shell mixin
#
# Provide a shortcut to Githosting::Shell instance by githosting_shell
#
module RedmineGitolite
  module ShellAdapter
    def githosting_shell
      RedmineGitolite::Shell.new
    end
  end
end
