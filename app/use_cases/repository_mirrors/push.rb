# frozen_string_literal: true

module RepositoryMirrors
  class Push < Base
    def call
      push!
    end

    def push!
      begin
        push_message = repository.mirror_push(*command)
        push_failed = false
      rescue RedmineGitHosting::Error::GitoliteCommandException => e
        push_message = e.output
        push_failed = true
      end

      [push_failed, push_message]
    end

    def command
      [mirror.url, branch, push_args]
    end

    private

    def push_args
      mirror.mirror_mode? ? ['--mirror'] : mirror_args
    end

    def mirror_args
      push_args = []
      push_args << '--force' if mirror.force_mode?
      push_args << '--all'   if mirror.include_all_branches?
      push_args << '--tags'  if mirror.include_all_tags?
      push_args
    end

    def branch
      dequote(mirror.explicit_refspec).to_s if mirror.explicit_refspec.present?
    end

    # Put backquote in front of crucial characters
    def dequote(in_string)
      in_string.gsub(/[$,"\\\n]/) { |x| '\\' + x }
    end
  end
end
