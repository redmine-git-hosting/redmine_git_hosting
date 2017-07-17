Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :redmine_git_hosting, { controller: 'settings', action: 'plugin', id: 'redmine_git_hosting' },
            caption: :redmine_git_hosting, html: { class: 'icon' }
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :archived_repositories, { controller: '/archived_repositories', action: 'index' },
            caption: :label_archived_repositories, after: :administration,
            if: Proc.new { User.current.logged? && User.current.admin? }
end
