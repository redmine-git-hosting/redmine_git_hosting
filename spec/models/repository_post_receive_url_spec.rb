require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryPostReceiveUrl do

  before do
    @project          = FactoryGirl.create(:project)
    @repository_git   = FactoryGirl.create(:repository, :project_id => @project.id)
    @post_receive_url = FactoryGirl.build(:repository_post_receive_url, :repository_id => @repository_git.id)
  end

  subject { @post_receive_url }

  it { should respond_to(:repository) }
  it { should respond_to(:url) }
  it { should respond_to(:active) }
  it { should respond_to(:use_triggers) }
  it { should respond_to(:triggers) }
  it { should respond_to(:split_payloads) }

  it { should be_valid }

  it { expect(@post_receive_url.active).to be true }
  it { expect(@post_receive_url.mode).to eq :github }
  it { expect(@post_receive_url.use_triggers).to be false }
  it { expect(@post_receive_url.triggers).to be_a(Array) }
  it { expect(@post_receive_url.split_payloads).to be false }

  ## Test presence validation
  describe "when repository_id is not present" do
    before { @post_receive_url.repository_id = "" }
    it { should_not be_valid }
  end

  describe "when url is not present" do
    before { @post_receive_url.url = "" }
    it { should_not be_valid }
  end

  describe "when active is true" do
    before { @post_receive_url.active = true }
    it { should be_valid }
    it { expect(@post_receive_url.active).to be true }
  end

  describe "when active is false" do
    before { @post_receive_url.active = false }
    it { should be_valid }
    it { expect(@post_receive_url.active).to be false }
  end

  describe "when use_triggers is true" do
    before { @post_receive_url.use_triggers = true }
    it { should be_valid }
    it { expect(@post_receive_url.use_triggers).to be true }
  end

  describe "when use_triggers is false" do
    before { @post_receive_url.use_triggers = false }
    it { should be_valid }
    it { expect(@post_receive_url.use_triggers).to be false }
  end

  describe "when triggers is set" do
    before { @post_receive_url.triggers = [ 'foo', 'bar', 'foobar' ] }
    it { should be_valid }
    it { expect(@post_receive_url.triggers).to eq [ 'foo', 'bar', 'foobar' ] }
  end

  describe "when triggers is unset" do
    before { @post_receive_url.triggers = [] }
    it { should be_valid }
    it { expect(@post_receive_url.triggers).to eq [] }
  end

  describe "when split_payloads is true" do
    before { @post_receive_url.split_payloads = true }
    it { should be_valid }
    it { expect(@post_receive_url.split_payloads).to be true }
  end

  describe "when split_payloads is false" do
    before { @post_receive_url.split_payloads = false }
    it { should be_valid }
    it { expect(@post_receive_url.split_payloads).to be false }
  end

  ## Test format validation
  describe "when url is valid" do
    it "should be valid" do
      addresses = [
        'http://toto.com/example.com',
        'https://toto.com/example.com'
      ]

      addresses.each do |valid_address|
        @post_receive_url.url = valid_address
        expect(@post_receive_url).to be_valid
      end
    end
  end

  describe "when mode is valid" do
    it "should be valid" do
      post_modes = [
        :github,
        :get
      ]

      post_modes.each do |valid_mode|
        @post_receive_url.mode = valid_mode
        expect(@post_receive_url).to be_valid
      end
    end
  end

  describe "when mode is not valid" do
    it "should be not valid" do
      post_modes = [
        :post
      ]

      post_modes.each do |invalid_mode|
        @post_receive_url.mode = invalid_mode
        expect(@post_receive_url).not_to be_valid
      end
    end
  end


  ## Test uniqueness validation
  describe "when post receive url is already taken" do
    before do
      @post_receive_url.save
      @post_receive_url_with_same_url = @post_receive_url.dup
      @post_receive_url_with_same_url.save
    end

    it { expect(@post_receive_url_with_same_url).not_to be_valid }
  end


  describe "when many post receive url are saved" do
    POST_RECEIVE_URL1 = 'http://example.com'
    POST_RECEIVE_URL2 = 'https://example.com'

    INACTIVE_POST_RECEIVE_URL3 = 'http://example.com/toto.php'
    INACTIVE_POST_RECEIVE_URL4 = 'https://example.com/toto.php'

    before do
      post_receive_url1 = FactoryGirl.create(:repository_post_receive_url, :repository_id => @repository_git.id, :url => POST_RECEIVE_URL1, :active => true)
      post_receive_url2 = FactoryGirl.create(:repository_post_receive_url, :repository_id => @repository_git.id, :url => POST_RECEIVE_URL2, :active => true)

      inactive_post_receive_url3 = FactoryGirl.create(:repository_post_receive_url, :repository_id => @repository_git.id, :url => INACTIVE_POST_RECEIVE_URL3, :active => false)
      inactive_post_receive_url4 = FactoryGirl.create(:repository_post_receive_url, :repository_id => @repository_git.id, :url => INACTIVE_POST_RECEIVE_URL4, :active => false)
    end

    it { expect(RepositoryPostReceiveUrl.active.length).to be == 2 }
    it { expect(RepositoryPostReceiveUrl.inactive.length).to be == 2 }
  end

  describe "#needs_push" do

    before do
      @global_payload   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../fixtures/global_payload.yml')))
      @master_payload   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../fixtures/master_payload.yml')))
      @branches_payload = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../fixtures/branches_payload.yml')))
    end

    context "when payload is empty" do
      before do
        @needs_push = @post_receive_url.needs_push([])
      end

      it "shoud return false" do
        expect(@needs_push).to be false
      end
    end

    context "when triggers are not used" do
      before do
        @needs_push = @post_receive_url.needs_push(@global_payload)
      end

      it "should return the global payload to push" do
        expect(@needs_push).to eq @global_payload
      end
    end

    context "when triggers are empty" do
      before do
        @post_receive_url.use_triggers = true
        @needs_push = @post_receive_url.needs_push(@global_payload)
      end

      it "should return the global payload to push" do
        expect(@needs_push).to eq @global_payload
      end
    end

    context "when triggers is set to master" do
      before do
        @post_receive_url.use_triggers = true
        @post_receive_url.triggers = [ 'master' ]
        @needs_push = @post_receive_url.needs_push(@global_payload)
      end

      it "should return the master payload" do
        expect(@needs_push).to eq @master_payload
      end
    end

    context "when triggers is set to master" do
      before do
        @post_receive_url.use_triggers = true
        @post_receive_url.triggers = [ 'master' ]
        @needs_push = @post_receive_url.needs_push(@branches_payload)
      end

      it "should not be found in branches payload and return false" do
        expect(@needs_push).to be false
      end
    end

  end

end
