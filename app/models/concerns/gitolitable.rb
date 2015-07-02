module Gitolitable
  extend ActiveSupport::Concern
  include Gitolitable::Authorizations
  include Gitolitable::Cache
  include Gitolitable::Config
  include Gitolitable::Features
  include Gitolitable::Notifications
  include Gitolitable::Paths
  include Gitolitable::Permissions
  include Gitolitable::Urls
  include Gitolitable::Users
  include Gitolitable::Validations
end
