FactoryGirl.define do

  factory :gitolite_public_key do |gitolite_public_key|
    gitolite_public_key.key_type 0
    gitolite_public_key.title    'test-key'
    gitolite_public_key.key      'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArPAhHP5+5eeiV/W6t4zUvGTPDp/e65lLVCq/180WiTMZJ5jOj+/lnrC/AF4LRlawr2mXUIOgf5i8QM0vNuoC+2oGEz7oymZJxS6fQmWfYz8fG2AXfsXjVwnlk9itp3IYMFXODYFTrgNSwxYHVF2j/4HYnzc7KFId6C9o/+hzK+LAae/1SufFd18nwJhSQmPwDBIX0dW6N/nbQ7hOkJFOQzHIh7D3KdP3KyhobsKOa1Q1zM3TIvOp7nzVcr416SNfxCYAw9Vs0v7X1L+6sD2x5Jkej5xYbJwYSIdKkgtTCPSBs7zG9Q05hHtSe7kOh/VJfWroUKn1nvxHXe/rbw421w== Maciek@MACIEK-PC'
  end

end
