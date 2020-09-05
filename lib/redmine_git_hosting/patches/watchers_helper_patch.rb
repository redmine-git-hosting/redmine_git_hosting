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

      def watcher_css_with_git_hosting(objects)
        watcher_css_without_git_hosting(objects).tr '/', '-'
      end

      def watchers_list_with_git_hosting(object)
        remove_allowed = User.current.allowed_to? "delete_#{object.class.name.underscore}_watchers".tr('/', '_').to_sym, object.project
        content = ''.html_safe
        object.watcher_users.preload(:email_address).each do |user|
          s = ''.html_safe
          s << avatar(user, size: '16').to_s
          s << link_to_user(user, class: 'user')
          if remove_allowed
            url = { controller: 'watchers',
                    action: 'destroy',
                    object_type: object.class.to_s.underscore,
                    object_id: object.id,
                    user_id: user }
            s << ' '
            s << link_to(l(:button_delete), url,
                         remote: true, method: 'delete',
                         class: 'delete icon-only icon-del',
                         title: l(:button_delete))
          end
          content << tag.li(s, class: "user-#{user.id}")
        end
        content.present? ? tag.ul(content, class: 'watchers') : content
      end
    end
  end
end

unless WatchersHelper.included_modules.include?(RedmineGitHosting::Patches::WatchersHelperPatch)
  WatchersHelper.prepend RedmineGitHosting::Patches::WatchersHelperPatch
end
