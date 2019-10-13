require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryPostReceiveUrl do

  let(:post_receive_url) { build(:repository_post_receive_url) }

  subject { post_receive_url }

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
  # it { should serialize(:triggers) }

  ## Attributes content
  it { expect(post_receive_url.active).to be true }
  it { expect(post_receive_url.mode).to eq :github }
  it { expect(post_receive_url.use_triggers).to be false }
  it { expect(post_receive_url.triggers).to be_a(Array) }
  it { expect(post_receive_url.split_payloads).to be false }


  # describe '.active' do
  #   it 'should return an array of active post_receive_urls' do
  #     expect(RepositoryPostReceiveUrl).to receive(:where).with(active: true)
  #     RepositoryPostReceiveUrl.active
  #   end
  # end


  # describe '.inactive' do
  #   it 'should return an array of inactive post_receive_urls' do
  #     expect(RepositoryPostReceiveUrl).to receive(:where).with(active: false)
  #     RepositoryPostReceiveUrl.inactive
  #   end
  # end

end
