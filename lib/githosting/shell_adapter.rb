# == Githosting Shell mixin
#
# Provide a shortcut to Githosting::Shell instance by githosting_shell
#
module Githosting
  module ShellAdapter
    def githosting_shell
      Githosting::Shell.new
    end
  end
end
