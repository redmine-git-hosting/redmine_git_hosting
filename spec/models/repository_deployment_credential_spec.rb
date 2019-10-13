require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryDeploymentCredential do

  DEPLOY_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz0pLXcQWS4gLUimUSLwDOvEmQF8l8EKoj0LjxOyM3y2dpLsn0aiqS0ecA0G/ROomaawop8EZGFetoJKJM468OZlx2aKoQemzvFIq0Mn1ZhcrlA1alAsDYqzZI8iHO4JIS3YbeLLkVGAlYA+bmA5enXN9mGhC9cgoMC79EZiLD9XvOw4iXDjqXaCzFZHU1shMWwaJfpyxBm+Mxs2vtZzwETDqeu9rohNMl60dODf6+JoXYiahP+B+P2iKlL7ORb1YsAH/4ZMsVgRckj8snb4uc3XgwLRNNw+oB78ApZGr0j3Zc32U9rpmulbHIroWO07OV4Xsplnu8lhGvfodA2gjb nicolas@tchoum'
  USER_KEY   = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5+JfM82k03J98GWL6ghJ4TYM8DbvDnVh1s1rUDNlM/1U5rwbgXHOR4xV3lulgYEYRtYeMoL3rt4ZpEyXWkOreOVsUlkW66SZJR5aGVTNJOLX7HruEDqj7RWlt0u0MH6DgBVAJimQrxYN50jYD4XnDUjb/qv55EhPvbJ3jcAb3zuyRXMKZYGNVzVFLUagbvVaOwR23csWSLDTsAEI9JzaxMKvCNRwk3jFepiCovXbw+g0iyvJdp0+AJpC57ZupyxHeX9J2oz7im2UaHHqLa2qUZL6c4PNV/D2p0Bts4Tcnn3OFPL90RF/ao0tjiUFxM3ti8pRHOqRcZHcOgIhKiaLX nicolas@tchoum'

  before(:all) do
    users = create_list(:user, 2)
    @user1 = users[0]
    @user2 = users[1]

    @deploy_key = create(:gitolite_public_key, user: @user1, key_type: 1, title: 'foo1', key: DEPLOY_KEY)
    @user_key   = create(:gitolite_public_key, user: @user1, key_type: 0, title: 'foo2', key: USER_KEY)
  end


  def build_deployment_credential(opts = {})
    build(:repository_deployment_credential, opts)
  end


  describe 'Valid RepositoryDeploymentCredential creation' do
    before(:each) do
      @deployment_credential = build_deployment_credential(user: @user1, gitolite_public_key: @deploy_key)
    end

    subject { @deployment_credential }

    ## Relations
    it { should belong_to(:repository) }
    it { should belong_to(:gitolite_public_key) }
    it { should belong_to(:user) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:gitolite_public_key_id) }
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:perm) }

    it { should validate_inclusion_of(:perm).in_array(%w(R RW+)) }

    ## Attributes content
    it 'is a active credential' do
      expect(@deployment_credential.active?).to be true
    end

    describe 'when active is false' do
      before { @deployment_credential.active = false }
      it 'shoud be inactive' do
        expect(@deployment_credential.active?).to be false
      end
    end
  end

  context 'when key is not a deployment key' do
    it 'should not be valid' do
      expect(build_deployment_credential(user: @user1, gitolite_public_key: @user_key)).not_to be_valid
    end
  end

  context 'when user id is not the owner of deployment key' do
    it 'should not be valid' do
      expect(build_deployment_credential(user: @user2, gitolite_public_key: @user_key)).not_to be_valid
    end
  end

end
