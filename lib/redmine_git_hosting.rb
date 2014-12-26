## Redmine SCM adapter
require 'redmine/scm/adapters/xitolite_adapter'

# Set up autoload of patches
Rails.configuration.to_prepare do

  ## Redmine Git Hosting Libs
  rbfiles = Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_gitolite', '**', '*.rb')
  Dir.glob(rbfiles).each do |file|
    require_dependency file
  end

  ## Redmine Git Hosting Patches
  rbfiles = Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_git_hosting', 'patches', '*.rb')
  Dir.glob(rbfiles).each do |file|
    require_dependency file
  end

  ## Redmine Git Hosting Hooks
  rbfiles = Rails.root.join('plugins', 'redmine_git_hosting', 'lib', 'redmine_git_hosting', 'hooks', '*.rb')
  Dir.glob(rbfiles).each do |file|
    require_dependency file
  end

end
