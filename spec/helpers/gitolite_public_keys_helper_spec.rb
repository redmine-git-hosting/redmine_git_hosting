require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GitolitePublicKeysHelper do
  TEST_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpOU1DzQzU4/acdt3wWhk43acGs3Jp7jVlnEtc+2C8QFAUiJMrAOzyUnEliwxarGonJ5gKbI9NkqqPpz9LATBQw382+3FjAlptgqn7eGBih0DgwN6wdHflTRdE6sRn7hxB5h50p547n26FpbX9GSOHPhgxSnyvGXnC+YZyTfMiw5JMhw68SfLS8YENrXukg2ItJPspn6mPqIHrcM2NJOG4Bm+1ibYpDfrWJqYp3Q6disgwrsN08pS6lDfoQRiRHXg8WFbQbHloVaYFpdT6VoBQiAydeSpDSYTBJd/v3qTpK8aheC8sdnrddZf1T6L51z7WZ6vPVKQYPjpAxZ4p6eef nicolas@tchoum'

  # before(:all) do
  #   @admin_user          = create_admin_user
  #   @user_without_perm   = create_anonymous_user
  #   @user_with_perm      = create_user_with_permissions(FactoryBot.create(:project), permissions: [:create_repository_deployment_credentials])
  #   @gitolite_public_key = create_ssh_key(user_id: @user_without_perm.id, key_type: 1, title: 'foo1', key: TEST_KEY)
  # end

  # describe '.keylabel' do
  #   context 'when current user is the key owner' do
  #     before { User.current = @user_without_perm }

  #     it { expect(helper.keylabel(@gitolite_public_key)).to eq 'foo1' }
  #   end

  #   context 'when current user is not the key owner' do
  #     before { User.current = @admin_user }

  #     it { expect(helper.keylabel(@gitolite_public_key)).to eq 'git_anonymous@foo1' }
  #   end
  # end

  # describe '.can_create_deployment_keys_for_some_project' do
  #   context 'when current user is admin' do
  #     it { expect(helper.can_create_deployment_keys_for_some_project(@admin_user)).to eq true }
  #   end

  #   context 'when current user can create_deployment_keys' do
  #     it { expect(helper.can_create_deployment_keys_for_some_project(@user_with_perm)).to eq true }
  #   end

  #   context 'when current user cannot create_deployment_keys' do
  #     it { expect(helper.can_create_deployment_keys_for_some_project(@user_without_perm)).to eq false }
  #   end
  # end
end
