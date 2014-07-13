require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryPostReceiveUrl do

  GLOBAL_PAYLOAD   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../fixtures/global_payload.yml')))
  MASTER_PAYLOAD   = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../fixtures/master_payload.yml')))
  BRANCHES_PAYLOAD = YAML::load(File.open(File.expand_path(File.dirname(__FILE__) + '/../fixtures/branches_payload.yml')))

  before(:all) do
    @project    = FactoryGirl.create(:project)
    @repository = FactoryGirl.create(:repository_git, :project_id => @project.id)
  end


  def build_post_receive_url(opts = {})
    opts = opts.merge(:repository_id => @repository.id)
    FactoryGirl.build(:repository_post_receive_url, opts)
  end


  def create_post_receive_url(opts = {})
    opts = opts.merge(:repository_id => @repository.id)
    FactoryGirl.create(:repository_post_receive_url, opts)
  end


  describe "Valid RepositoryPostReceiveUrl creation" do
    before do
      @post_receive_url = build_post_receive_url
    end

    subject { @post_receive_url }

    ## Attributes
    it { should allow_mass_assignment_of(:url) }
    it { should allow_mass_assignment_of(:mode) }
    it { should allow_mass_assignment_of(:active) }
    it { should allow_mass_assignment_of(:use_triggers) }
    it { should allow_mass_assignment_of(:triggers) }
    it { should allow_mass_assignment_of(:split_payloads) }

    ## Relations
    it { should belong_to(:repository) }

    ## Validations
    it { should be_valid }

    it { should validate_presence_of(:repository_id) }
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:mode) }

    it { should validate_uniqueness_of(:url).scoped_to(:repository_id) }

    it {
      should ensure_inclusion_of(:mode).
      in_array([:github, :get])
    }

    it {
      should allow_value('http://foo.com', 'https://bar.com/baz').
      for(:url)
    }

    ## Serializations
    it { should serialize(:triggers) }

    ## Attributes content
    it { expect(@post_receive_url.active).to be true }
    it { expect(@post_receive_url.mode).to eq :github }
    it { expect(@post_receive_url.use_triggers).to be false }
    it { expect(@post_receive_url.triggers).to be_a(Array) }
    it { expect(@post_receive_url.split_payloads).to be false }

    describe "when active is true" do
      before { @post_receive_url.active = true }
      it { expect(@post_receive_url.active).to be true }
    end

    describe "when active is false" do
      before { @post_receive_url.active = false }
      it { expect(@post_receive_url.active).to be false }
    end

    describe "when use_triggers is true" do
      before { @post_receive_url.use_triggers = true }
      it { expect(@post_receive_url.use_triggers).to be true }
    end

    describe "when use_triggers is false" do
      before { @post_receive_url.use_triggers = false }
      it { expect(@post_receive_url.use_triggers).to be false }
    end

    describe "when split_payloads is true" do
      before { @post_receive_url.split_payloads = true }
      it { expect(@post_receive_url.split_payloads).to be true }
    end

    describe "when split_payloads is false" do
      before { @post_receive_url.split_payloads = false }
      it { expect(@post_receive_url.split_payloads).to be false }
    end
  end


  context "when many post receive url are saved" do
    before do
      create_post_receive_url(:active => true)
      create_post_receive_url(:active => true)
      create_post_receive_url(:active => false)
      create_post_receive_url(:active => false)
    end

    it { expect(RepositoryPostReceiveUrl.active.length).to be == 3 }
    it { expect(RepositoryPostReceiveUrl.inactive.length).to be == 2 }
  end


  describe "#needs_push" do
    before do
      @post_receive_url = build_post_receive_url
    end

    subject { @post_receive_url }

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
        @needs_push = @post_receive_url.needs_push(GLOBAL_PAYLOAD)
      end

      it "should return the global payload to push" do
        expect(@needs_push).to eq GLOBAL_PAYLOAD
      end
    end

    context "when triggers are empty" do
      before do
        @post_receive_url.use_triggers = true
        @needs_push = @post_receive_url.needs_push(GLOBAL_PAYLOAD)
      end

      it "should return the global payload to push" do
        expect(@needs_push).to eq GLOBAL_PAYLOAD
      end
    end

    context "when triggers is set to master" do
      before do
        @post_receive_url.use_triggers = true
        @post_receive_url.triggers = [ 'master' ]
        @needs_push = @post_receive_url.needs_push(GLOBAL_PAYLOAD)
      end

      it "should return the master payload" do
        expect(@needs_push).to eq MASTER_PAYLOAD
      end
    end

    context "when triggers is set to master" do
      before do
        @post_receive_url.use_triggers = true
        @post_receive_url.triggers = [ 'master' ]
        @needs_push = @post_receive_url.needs_push(BRANCHES_PAYLOAD)
      end

      it "should not be found in branches payload and return false" do
        expect(@needs_push).to be false
      end
    end
  end

end
