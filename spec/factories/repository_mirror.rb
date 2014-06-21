FactoryGirl.define do

  factory :repository_mirror do |mirror|
    mirror.url       'ssh://host.xz/path/to/repo.git'
    mirror.push_mode 0
  end

end
