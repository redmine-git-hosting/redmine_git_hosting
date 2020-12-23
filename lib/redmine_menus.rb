Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :redmine_git_hosting, { controller: 'settings', action: 'plugin', id: 'redmine_git_hosting' },
            caption: :redmine_git_hosting, html: { class: 'icon' }
end
