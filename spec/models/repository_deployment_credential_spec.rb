require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryDeploymentCredential do

  GOOD_SSH_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz0pLXcQWS4gLUimUSLwDOvEmQF8l8EKoj0LjxOyM3y2dpLsn0aiqS0ecA0G/ROomaawop8EZGFetoJKJM468OZlx2aKoQemzvFIq0Mn1ZhcrlA1alAsDYqzZI8iHO4JIS3YbeLLkVGAlYA+bmA5enXN9mGhC9cgoMC79EZiLD9XvOw4iXDjqXaCzFZHU1shMWwaJfpyxBm+Mxs2vtZzwETDqeu9rohNMl60dODf6+JoXYiahP+B+P2iKlL7ORb1YsAH/4ZMsVgRckj8snb4uc3XgwLRNNw+oB78ApZGr0j3Zc32U9rpmulbHIroWO07OV4Xsplnu8lhGvfodA2gjb nicolas@tchoum'
  BAD_SSH_KEY  = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5+JfM82k03J98GWL6ghJ4TYM8DbvDnVh1s1rUDNlM/1U5rwbgXHOR4xV3lulgYEYRtYeMoL3rt4ZpEyXWkOreOVsUlkW66SZJR5aGVTNJOLX7HruEDqj7RWlt0u0MH6DgBVAJimQrxYN50jYD4XnDUjb/qv55EhPvbJ3jcAb3zuyRXMKZYGNVzVFLUagbvVaOwR23csWSLDTsAEI9JzaxMKvCNRwk3jFepiCovXbw+g0iyvJdp0+AJpC57ZupyxHeX9J2oz7im2UaHHqLa2qUZL6c4PNV/D2p0Bts4Tcnn3OFPL90RF/ao0tjiUFxM3ti8pRHOqRcZHcOgIhKiaLX nicolas@tchoum'

  before do
    @project        = FactoryGirl.create(:project)
    @repository_git = FactoryGirl.create(:repository, :project_id => @project.id)

    users = FactoryGirl.create_list(:user, 2)
    @user1 = users[0]
    @user2 = users[1]

    @good_ssh_key = FactoryGirl.create(:gitolite_public_key, :user_id => @user1.id, :key_type => 1, :title => 'foo1', :key => GOOD_SSH_KEY)
    @bad_ssh_key  = FactoryGirl.create(:gitolite_public_key, :user_id => @user1.id, :key_type => 0, :title => 'foo2', :key => BAD_SSH_KEY)

    @deployment_credential = FactoryGirl.build(:repository_deployment_credential, :repository_id          => @repository_git.id,
                                                                                  :gitolite_public_key_id => @good_ssh_key.id,
                                                                                  :user_id                => @user1.id)
  end

  subject { @deployment_credential }

  it { should be_valid }

  it { should respond_to(:repository) }
  it { should respond_to(:gitolite_public_key) }
  it { should respond_to(:user) }
  it { should respond_to(:perm) }
  it { should respond_to(:active) }

  it "is a active credential" do
    expect(@deployment_credential.active?).to be true
  end

  ## Test presence validation
  describe "when repository_id is not present" do
    before { @deployment_credential.repository_id = "" }
    it { should_not be_valid }
  end

  describe "when gitolite_public_key_id is not present" do
    before { @deployment_credential.gitolite_public_key_id = "" }
    it { should_not be_valid }
  end

  describe "when user_id is not present" do
    before { @deployment_credential.user_id = "" }
    it { should_not be_valid }
  end

  describe "when perm is not present" do
    before { @deployment_credential.perm = "" }
    it { should_not be_valid }
  end

  describe "when active is false" do
    before { @deployment_credential.active = false }
    it 'shoud be inactive' do
      expect(@deployment_credential.active?).to be false
    end
  end

  ## Test format validation
  describe "when perm is valid" do
    perms = [
      'R',
      'RW+'
    ]

    perms.each do |valid_perm|
      it "should be valid" do
        @deployment_credential.perm = valid_perm
        expect(@deployment_credential).to be_valid
      end
    end
  end

  describe "when perm is invalid" do
    it "should be invalid" do
      perms = [
        'foo',
        'bar'
      ]

      perms.each do |invalid_perm|
        @deployment_credential.perm = invalid_perm
        expect(@deployment_credential).not_to be_valid
      end
    end
  end


  ## Test special validation
  describe "when user id is not the owner of deployment key" do
    before do
      @deployment_credential.user_id = @user2.id
    end

    it { should_not be_valid }
  end

  describe "when key is not a deployment key" do
    before do
      @deployment_credential.gitolite_public_key_id = @bad_ssh_key.id
    end

    it { should_not be_valid }
  end

end
