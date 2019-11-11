require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryProtectedBranche do

  let(:protected_branch) { build(:repository_protected_branche) }

  subject { protected_branch }

  ## Relations
  it { should belong_to(:repository) }
  it { should have_many(:protected_branches_members).with_foreign_key(:protected_branch_id).dependent(:destroy) }
  it { should have_many(:members).through(:protected_branches_members) }

  ## Validations
  it { should be_valid }

  it { should validate_presence_of(:repository_id) }
  it { should validate_presence_of(:path) }
  it { should validate_presence_of(:permissions) }

  it { should validate_uniqueness_of(:path).scoped_to([:permissions, :repository_id]) }

  it { should validate_inclusion_of(:permissions).in_array RepositoryProtectedBranche::VALID_PERMS }

  describe '#users' do
    it 'should return an array of users' do
      user  = build(:user)
      group = build(:group)
      expect(protected_branch).to receive(:members).and_return([user, user, group])
      expect(protected_branch.users).to eq [user]
    end
  end

  describe '#groups' do
    it 'should return an array of groups' do
      user  = build(:user)
      group = build(:group)
      expect(protected_branch).to receive(:members).and_return([group, user, group])
      expect(protected_branch.groups).to eq [group]
    end
  end

  describe '#allowed_users' do
    it 'should return an array of gitolite identifiers' do
      user1 = build(:user)
      user2 = build(:user)
      expect(protected_branch).to receive(:users).and_return([user1, user2])
      expect(protected_branch.allowed_users).to eq [user1.gitolite_identifier, user2.gitolite_identifier]
    end
  end

end
