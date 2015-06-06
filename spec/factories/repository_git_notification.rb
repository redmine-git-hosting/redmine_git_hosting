FactoryGirl.define do

  factory :repository_git_notification do |f|
    f.prefix          '[TEST PROJECT]'
    f.sender_address  'redmine@example.com'
    f.include_list    ['foo@bar.com', 'bar@foo.com']
    f.exclude_list    ['far@boo.com', 'boo@far.com']
    f.association     :repository, factory: :repository_gitolite
  end

end
