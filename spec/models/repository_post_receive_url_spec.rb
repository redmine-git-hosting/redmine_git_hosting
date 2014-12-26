require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryPostReceiveUrl do

  describe "Valid RepositoryPostReceiveUrl creation" do
    before(:each) do
      @post_receive_url = build(:repository_post_receive_url)
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

    it { should validate_inclusion_of(:mode).in_array([:github, :get]) }

    it { should allow_value('http://foo.com', 'https://bar.com/baz').for(:url) }

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
      create(:repository_post_receive_url, :active => true)
      create(:repository_post_receive_url, :active => true)
      create(:repository_post_receive_url, :active => false)
      create(:repository_post_receive_url, :active => false)
    end

    it { expect(RepositoryPostReceiveUrl.active.length).to be == 3 }
    it { expect(RepositoryPostReceiveUrl.inactive.length).to be == 2 }
  end

end
