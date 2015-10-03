require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryGitExtra do

  let(:git_extra) { build(:repository_git_extra) }

  subject { git_extra }

  ## Attributes
  it { should allow_mass_assignment_of(:git_http) }
  it { should allow_mass_assignment_of(:git_daemon) }
  it { should allow_mass_assignment_of(:git_notify) }
  it { should allow_mass_assignment_of(:git_annex) }
  it { should allow_mass_assignment_of(:default_branch) }
  it { should allow_mass_assignment_of(:protected_branch) }
  it { should allow_mass_assignment_of(:public_repo) }
  it { should allow_mass_assignment_of(:key) }
  it { should allow_mass_assignment_of(:urls_order) }

  ## Relations
  it { should belong_to(:repository) }

  ## Validations
  it { should be_valid }

  it { should validate_presence_of(:repository_id) }
  it { should validate_presence_of(:git_http) }
  it { should validate_presence_of(:default_branch) }
  it { should validate_presence_of(:key) }

  it { should validate_uniqueness_of(:repository_id) }

  it { should validate_numericality_of(:git_http) }

  it { should validate_inclusion_of(:git_http).in_array(%w(0 1 2 3)) }

  ## Serializations
  it { should serialize(:urls_order) }


  describe '#git_http' do
    it 'should return the value for git_http' do
      expect(git_extra.git_http).to eq 0
    end
  end

  describe '#git_daemon' do
    it 'should return the value for git_daemon' do
      expect(git_extra.git_daemon).to be true
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
