require_dependency 'watchers_helper'

# This patch fix http://www.redmine.org/issues/12348

module RedmineGitHosting
  module Patches
    module WatchersHelperPatch

      def self.prepended(base)
        base.class_eval do
          alias_method :watcher_css_without_git_hosting, :watcher_css
          alias_method :watcher_css, :watcher_css_with_git_hosting

          alias_method :watchers_list_without_git_hosting, :watchers_list
          alias_method :watchers_list, :watchers_list_with_git_hosting
        end
      end


      def watcher_css_with_git_hosting(objects, &block)
        watcher_css_without_git_hosting(objects, &block).gsub('/', '-')
      end


      def watchers_list_with_git_hosting(object, &block)
        remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".gsub('/', '_').to_sym, object.project)
        content = ''.html_safe
        lis = object.watcher_users.collect do |user|
          s = ''.html_safe
          s << avatar(user, :size => "16").to_s
          s << link_to_user(user, :class => 'user')
          if remove_allowed
            url = {:controller => 'watchers',
                   :action => 'destroy',
                   :object_type => object.class.to_s.underscore,
                   :object_id => object.id,
                   :user_id => user}
            s << ' '
            s << link_to(image_tag('delete.png'), url,
                         :remote => true, :method => 'delete', :class => "delete")
          end
          content << content_tag('li', s, :class => "user-#{user.id}")
        end
        content.present? ? content_tag('ul', content, :class => 'watchers') : content
      end

    end
  end
end

unless WatchersHelper.included_modules.include?(RedmineGitHosting::Patches::WatchersHelperPatch)
  WatchersHelper.send(:prepend, RedmineGitHosting::Patches::WatchersHelperPatch)
end
