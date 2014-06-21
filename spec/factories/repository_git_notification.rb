FactoryGirl.define do

  factory :repository_git_notification do |git_notification|
    git_notification.prefix          '[TEST PROJECT]'
    git_notification.sender_address  'redmine@example.com'
    git_notification.include_list    [ 'foo@bar.com', 'bar@foo.com']
    git_notification.exclude_list    [ 'far@boo.com', 'boo@far.com']
  end

end
