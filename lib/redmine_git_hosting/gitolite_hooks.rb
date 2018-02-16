module RedmineGitHosting
  module GitoliteHooks

    class << self

      def register_hooks(&block)
        @gitolite_hooks ||= []
        class_eval(&block)
      end


      def registered_hooks
        @gitolite_hooks
      end


      def source_dir(source_dir)
        @source_dir = source_dir
      end


      def hooks_installed?
        installed = {}
        registered_hooks.each do |hook|
          begin
            installed[hook.name] = hook.installed?
          rescue Exception => msg
            installed[hook.name] = false
          end
        end
        installed
      end


      def install_hooks!
        installed = {}
        registered_hooks.each do |hook|
          installed[hook.name] = hook.install!
        end
        installed
      end


      def gitolite_hook(&block)
        @gitolite_hooks << RedmineGitHosting::GitoliteHook.new(@source_dir, &block)
      end

    end

  end
end
