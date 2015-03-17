module Gitolitable
  extend ActiveSupport::Concern
  include Gitolitable::Cache
  include Gitolitable::Features
  include Gitolitable::Notifications
  include Gitolitable::Paths
  include Gitolitable::Permissions
  include Gitolitable::Urls
  include Gitolitable::Validations
end
