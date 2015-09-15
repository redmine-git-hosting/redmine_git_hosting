require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do

  describe 'GET #edit' do
    context 'with git hosting patch' do
      let(:user) { create_admin_user }
      let(:user_key) { create_ssh_key(user_id: user.id, title: 'user_key', key: Faker::Ssh.public_key, key_type: 0) }
      let(:deploy_key) { create_ssh_key(user_id: user.id, title: 'deploy_key', key: Faker::Ssh.public_key, key_type: 1) }

      it 'populates an array of gitolite_user_keys' do
        set_session_user(user)
        get :edit, id: user.id
        expect(assigns(:gitolite_user_keys)).to eq [user_key]
      end

      it 'populates an array of gitolite_deploy_keys' do
        set_session_user(user)
        get :edit, id: user.id
        expect(assigns(:gitolite_deploy_keys)).to eq [deploy_key]
      end
    end
  end

end
