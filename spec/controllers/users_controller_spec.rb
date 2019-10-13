require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'sshkey'

describe UsersController do
  describe 'GET #edit' do
    context 'with git hosting patch' do
      let(:user) { create_admin_user }
      let(:user_key) do
        create_ssh_key(user_id: user.id,
                       title: 'user_key',
                       key: SSHKey.generate(comment: 'faker_user_key@john_doe').ssh_public_key,
                       key_type: 0)
      end
      let(:deploy_key) do
        create_ssh_key(user_id: user.id,
                       title: 'deploy_key',
                       key: SSHKey.generate(comment: 'faker_deploy_key@john_doe').ssh_public_key,
                       key_type: 1)
      end

      it 'populates an array of gitolite_user_keys' do
        set_session_user(user)
        get :edit,
            params: { id: user.id }
        expect(assigns(:gitolite_user_keys)).to eq [user_key]
      end

      # it 'populates an array of gitolite_deploy_keys' do
      #   set_session_user(user)
      #   get :edit,
      #       params: { id: user.id }
      #   expect(assigns(:gitolite_deploy_keys)).to eq [deploy_key]
      # end
    end
  end
end
