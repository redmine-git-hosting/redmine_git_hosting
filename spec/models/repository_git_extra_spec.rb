require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitExtra do

  let(:git_extra) { build(:repository_git_extra) }

  subject { git_extra }

  ## Relations
  it { should belong_to(:repository) }

  ## Validations
  it { should be_valid }

  it { should validate_presence_of(:repository_id) }
  it { should validate_presence_of(:default_branch) }
  it { should validate_presence_of(:key) }

  it { should validate_uniqueness_of(:repository_id) }

  ## Serializations
  # it { should serialize(:urls_order) }


  describe '#git_daemon' do
    it 'should return the value for git_daemon' do
      expect(git_extra.git_daemon).to be true
    end
  end

  describe '#git_http' do
    it 'should return the value for git_http' do
      expect(git_extra.git_http).to be false
    end
  end

  describe '#git_https' do
    it 'should return the value for git_https' do
      expect(git_extra.git_https).to be false
    end
  end

  describe '#git_go' do
    it 'should return the value for git_go' do
      expect(git_extra.git_go).to be false
    end
  end

  describe '#git_ssh' do
    it 'should return the value for git_ssh' do
      expect(git_extra.git_ssh).to be true
    end
  end

  describe '#git_notify' do
    it 'should return the value for git_notify' do
      expect(git_extra.git_notify).to be true
    end
  end

  describe '#default_branch' do
    it 'should return the value for default_branch' do
      expect(git_extra.default_branch).to eq 'master'
    end
  end

  describe '#protected_branch' do
    it 'should return the value for protected_branch' do
      expect(git_extra.protected_branch).to be false
    end
  end

  describe '#key' do
    it 'should return the value for key' do
      expect(git_extra.key).to match /\A[a-zA-Z0-9]+\z/
    end
  end
end
